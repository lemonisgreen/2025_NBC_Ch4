//
//  UserPostsViewModel.swift
//  SherlDog
//
//  Created by JIN LEE on 9/26/25.
//

import RxSwift
import RxCocoa
import RxDataSources
import Differentiator

final class UserPostsViewModel {
    
    // MARK: - Input & Output
    struct Input {
        let segmentIndexChanged: Observable<Int>
        let pullToRefresh: Observable<Void>
        let manualRefresh: Observable<Void>
        let fetchMore: Observable<Void>
        let menuEvent: Observable<PostMenuEvent>
        let likeEvent: Observable<CommunityModel>
    }
    
    struct Output {
        let selectedCategory: Driver<CommunitySectionType>
        let currentCellData: Driver<[CommunitySectionType: [CommunityViewModel.CommunitySection]]>
        let isUpdating: Driver<Bool>
        let menuComplete: Signal<PostMenuEvent>
    }
    
    private let disposeBag = DisposeBag()
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    // MARK: - Transform
    func transform(_ input: Input) -> Output {
        // 선택된 카테고리
        let selectedCategory = input.segmentIndexChanged
            .map { idx in CommunitySectionType.allCases[idx] ?? .invLogBoard }
            .startWith(.invLogBoard)
            .share(replay: 1)
        
        // 메뉴 이벤트
        let menu = menuButtonEvent(input.menuEvent, category: selectedCategory)
        
        // 새로고침 트리거
        let refreshTrigger = Observable.merge(
            selectedCategory.map { _ in () },
            input.pullToRefresh,
            input.manualRefresh,
            menu.asObservable().map { _ in () }
        )
        
        // 데이터 fetch (유저 필터 적용)
        let fetchStream = refreshTrigger
            .withLatestFrom(selectedCategory)
            .flatMapLatest { [weak self] category -> Observable<Event<[CommunityModel]>> in
                guard let self else { return .empty() }
                return self.fetchUserPosts(category: category, userId: self.userId)
                    .asObservable()
                    .materialize()
            }
            .share()
        
        // 로딩 상태
        let isUpdating = Observable.merge(
            refreshTrigger.map { true },
            fetchStream.map { _ in false }
        )
        .startWith(false)
        .distinctUntilChanged()
        .asDriver(onErrorJustReturn: false)
        
        // 성공 이벤트 → Mutation
        let refreshMutation = fetchStream
            .compactMap { $0.element }
            .withLatestFrom(selectedCategory) { posts, category in
                (category, posts)
            }
        
        // 상태 축적
        let postsDict = refreshMutation
            .scan(into: [CommunitySectionType: [CommunityModel]]()) { dict, mutation in
                let (category, posts) = mutation
                dict[category] = posts
            }
            .share(replay: 1)
        
        // Cell 데이터 매핑 (CommunitySection 재사용)
        let currentCellData = postsDict
            .map { dict in
                dict.mapValues { posts in
                    posts.map { CommunityViewModel.CommunitySection(model: $0, items: $0.contentImage) }
                }
            }
            .asDriver(onErrorJustReturn: [:])
        
        // 좋아요 sideEffect
        input.likeEvent
            .withLatestFrom(selectedCategory) { ($0, $1) }
            .flatMapFirst { model, category -> Completable in
                CommunityActionManager.shared.toggleLikeWithCount(
                    collection: category.toFirestoreCollection,
                    postCode: model.documentId
                )
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        return Output(
            selectedCategory: selectedCategory.asDriver(onErrorJustReturn: .invLogBoard),
            currentCellData: currentCellData,
            isUpdating: isUpdating,
            menuComplete: menu
        )
    }
}

// MARK: - Networking & Helpers
private extension UserPostsViewModel {
    
    func fetchUserPosts(category: CommunitySectionType, userId: String) -> Single<[CommunityModel]> {
        let collection = category.toFirestoreCollection
        
        return BlockManager.shared.fetchBlockedUserIds()
            .flatMap { blocked in
                FirestoreManager.shared.fetchQuery(FirestoreQuery<CommunityModel>(
                    collection: collection,
                    type: .collection(sortField: SDLiteral.CommunityView.postDate,
                                      descending: true,
                                      blockedIds: blocked)
                ))
            }
            .map { posts in
                posts.filter { $0.userId == userId } // 유저 필터
            }
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.instance)
    }
    
    func menuButtonEvent(_ input: Observable<PostMenuEvent>,
                         category: Observable<CommunitySectionType>) -> Signal<PostMenuEvent> {
        input
            .withLatestFrom(category) { ($0, $1) }
            .flatMapLatest { menu, category -> Observable<PostMenuEvent> in
                let collection = category.toFirestoreCollection
                switch menu {
                case .fix: return .just(.fix)
                case .delete(let docId):
                    return FirestoreManager.shared.deleteDocument(collection: collection, documentId: docId)
                        .andThen(.just(.delete(docId)))
                        .catchAndReturn(.error)
                case .report(let docId):
                    return FirestoreManager.shared.createDocument(
                        collection: .reportLog,
                        data: ReportModel(collection: collection.rawValue, documentId: docId),
                        documentId: docId
                    )
                    .andThen(.just(.report(docId)))
                    .catchAndReturn(.error)
                case .block(let postUserId):
                    return BlockManager.shared.blockUser(postUserId)
                        .andThen(.just(.block(postUserId)))
                        .catchAndReturn(.error)
                case .error: return .just(.error)
                }
            }
            .asSignal(onErrorJustReturn: .error)
    }
}
