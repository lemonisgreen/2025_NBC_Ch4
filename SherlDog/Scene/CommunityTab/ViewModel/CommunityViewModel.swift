//
//  CommunityViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 8/6/25.
//

import RxSwift
import RxCocoa
import RxDataSources
import Differentiator
import FirebaseAuth

final class CommunityViewModel {
    
    // 게시판 종류
    enum CommunitySectionType: CaseIterable {
        case invLogBoard
        case detectiveMateBoard
        
        var name: String {
            switch self {
            case .invLogBoard:        return SDLiteral.CommunityView.invLogBoardTitle
            case .detectiveMateBoard: return SDLiteral.CommunityView.detectiveMateTitle
            }
        }
        
        var collectionName: String {
            switch self {
            case .invLogBoard:        return SDLiteral.CollectionName.invLogBoard.rawValue
            case .detectiveMateBoard: return SDLiteral.CollectionName.detectiveMate.rawValue
            }
        }
    }
    
    // 데이터 변경 Mutation
    enum Mutation {
        case set(category: CommunitySectionType, posts: [CommunityModel])
        case append(category: CommunitySectionType, posts: [CommunityModel])
    }
    
    // MARK: - Input & Output
    struct Input {
        let segmentIndexChanged: Observable<Int>
        let pullToRefresh: Observable<Void>
        let fetchMore: Observable<Void>
        let menuEvent: Observable<PostMenuEvent>
        let likeEvent: Observable<CommunityModel>
    }
    
    struct Output {
        let selectedCategory: Driver<CommunitySectionType>
        let currentCellData: Driver<[CommunitySectionType: [CommunitySection]]>
        let isUpdating: Driver<Bool>
        let menuComplete: Signal<PostMenuEvent>
    }
    
    typealias CommunitySection = SectionModel<CommunityModel, String>
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Transform
    func transform(_ input: Input) -> Output {
        // 선택된 카테고리
        let selectedCategory = makeSelectedCategory(from: input.segmentIndexChanged)
        
        // Menu event
        let menu = menuButtonEvent(input.menuEvent, category: selectedCategory)
        
        // Like event
        let likeEvent = like(input.likeEvent, category: selectedCategory)
        
        // 새로고침을 하는 상황
        let refreshTrigger = makeRefreshTrigger(trigger: [
            selectedCategory.map { _ in () },
            input.pullToRefresh,
            menu.asObservable().map { _ in () },
            likeEvent
        ])
        
        // 데이터 불러오기
        let fetchStream = makeFetchStream(refreshTrigger: refreshTrigger,
                                          selectedCategory: selectedCategory)
        
        // 업데이트 중인지 표시
        let isUpdating = makeIsUpdating(refreshTrigger: refreshTrigger,
                                        fetchStream: fetchStream)
        
        // mutations
        let refreshMutation = makeRefreshMutation(postsEvent: fetchStream,
                                                  selectedCategory: selectedCategory)
        let appendMutation = makeAppendMutation(fetchMore: input.fetchMore,
                                                selectedCategory: selectedCategory)
        
        // state(store)
        let postsDict = makePostsDict(refreshMutation: refreshMutation,
                                      appendMutation: appendMutation)
        let currentCellData = mapPostsToSections(postsDict)
        
        return Output(
            selectedCategory: selectedCategory.asDriver(onErrorJustReturn: .invLogBoard),
            currentCellData: currentCellData,
            isUpdating: isUpdating,
            menuComplete: menu
        )
    }
}

// MARK: - Pipeline builders
private extension CommunityViewModel {
    
    // 선택된 카테고리
    func makeSelectedCategory(from segmentIndexChanged: Observable<Int>)
    -> Observable<CommunitySectionType> {
        segmentIndexChanged
            .map { idx in
                CommunitySectionType.allCases.indices.contains(idx)
                ? CommunitySectionType.allCases[idx]
                : .invLogBoard
            }
            .startWith(.invLogBoard)
            .share(replay: 1)
    }
    
    // 새로고침 트리거
    func makeRefreshTrigger(trigger: [Observable<Void>])
    -> Observable<Void> {
        Observable.merge(trigger)
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .share()
    }
    
    // fetch 스트림 (Event로 materialize)
    func makeFetchStream(refreshTrigger: Observable<Void>,
                         selectedCategory: Observable<CommunitySectionType>)
    -> Observable<Event<[CommunityModel]>> {
        refreshTrigger
            .withLatestFrom(selectedCategory)
            .flatMapLatest { [weak self] category -> Observable<Event<[CommunityModel]>> in
                guard let self else { return .empty() }
                return self.fetchPosts(category: category)
                    .asObservable()
                    .materialize()
            }
            .share()
    }
    
    // 로딩 토글
    func makeIsUpdating(refreshTrigger: Observable<Void>,
                        fetchStream: Observable<Event<[CommunityModel]>>)
    -> Driver<Bool> {
        Observable.merge(
            refreshTrigger.map { true },
            fetchStream.map { _ in false } // 성공/실패 모두 off
        )
        .startWith(false)
        .distinctUntilChanged()
        .asDriver(onErrorJustReturn: false)
    }
    
    // set 변이 (성공 이벤트만)
    func makeRefreshMutation(postsEvent: Observable<Event<[CommunityModel]>>,
                             selectedCategory: Observable<CommunitySectionType>)
    -> Observable<Mutation> {
        let posts = postsEvent.compactMap { $0.element }
        return posts
            .withLatestFrom(selectedCategory) { posts, category in
                Mutation.set(category: category, posts: posts)
            }
    }
    
    // append 변이 (TODO: 페이지네이션 위치)
    func makeAppendMutation(fetchMore: Observable<Void>,
                            selectedCategory: Observable<CommunitySectionType>)
    -> Observable<Mutation> {
        fetchMore
            .withLatestFrom(selectedCategory)
            .map { category in
                // TODO: 실제 더 불러오기 로직으로 교체
                    .append(category: category, posts: [])
            }
    }
    
    // 상태(Store) 축적
    func makePostsDict(refreshMutation: Observable<Mutation>,
                       appendMutation: Observable<Mutation>)
    -> Observable<[CommunitySectionType : [CommunityModel]]> {
        Observable.merge(refreshMutation, appendMutation)
            .scan(makeInitialPosts()) { dict, mutation in
                var next = dict
                switch mutation {
                case let .set(category, posts):
                    next[category] = posts
                case let .append(category, posts):
                    next[category, default: []] += posts
                }
                return next
            }
            .share(replay: 1)
    }
    
    // 섹션 매핑 → Driver
    func mapPostsToSections(_ postsDict: Observable<[CommunitySectionType : [CommunityModel]]>)
    -> Driver<[CommunitySectionType: [CommunitySection]]> {
        postsDict
            .map { dict in
                dict.mapValues { posts in
                    posts.map { CommunitySection(model: $0, items: $0.contentImage) }
                }
            }
            .asDriver(onErrorJustReturn: [:])
    }
}

// MARK: - Like Button Event
extension CommunityViewModel {
    private func like(_ input: Observable<CommunityModel>, category: Observable<CommunitySectionType>) -> Observable<Void> {
        return input
            .withLatestFrom(category) { ($0, $1) }
            .flatMapFirst { [weak self] (data, category) -> Observable<Void> in
                guard let self, let userId = Auth.auth().currentUser?.uid else { return .empty() }
                
                let newLiker = data.like.contains(userId)
                ? data.like.filter { $0 != userId }
                : (data.like + [userId])
                
                return self.findPostId(section: category, postCode: data.postCode)
                    .asObservable()
                    .flatMap { id -> Observable<Void> in
                        guard !id.isEmpty else { return .empty() }
                        var updateData = data
                        updateData.like = newLiker
                        return FirestoreManager.shared.updateDocument(collection: category.collectionName, documentId: id, data: updateData)
                            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                            .andThen(.just(()))
                    }
            }
    }
}

// MARK: - Menu Button Event
private extension CommunityViewModel {
    func menuButtonEvent(_ input: Observable<PostMenuEvent>,
                         category: Observable<CommunitySectionType>) -> Signal<PostMenuEvent> {
        input
            .withLatestFrom(category) { ($0, $1) }
            .flatMapLatest { [weak self] (menu, category) -> Observable<PostMenuEvent> in
                guard let self else { return .empty() }
                
                switch menu {
                case .fix:
                    return .just(.fix)
                    
                case .delete(let postCode):
                    return self.findPostId(section: category, postCode: postCode)
                        .flatMapCompletable { postId in
                            FirestoreManager.shared.deleteDocument(
                                collection: category.collectionName,
                                documentId: postId
                            )
                            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                        }
                        .andThen(.just(.delete(postCode)))
                        .catchAndReturn(.error)
                    
                case .report(let postCode):
                    // TODO: Report
                    return .just(.report(postCode))
                    
                case .block(let postUserId):
                    return BlockManager.shared.blockUser(postUserId)
                        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                        .andThen(.just(.block(postUserId)))
                        .catchAndReturn(.error)
                    
                case .error:
                    return .just(.error)
                }
            }
            .asSignal(onErrorJustReturn: .error)
    }
}

// MARK: - Initial / Networking helpers
private extension CommunityViewModel {
    // 초기 세팅: nil 방지
    func makeInitialPosts() -> [CommunitySectionType : [CommunityModel]] {
        var dict: [CommunitySectionType: [CommunityModel]] = [:]
        CommunitySectionType.allCases.forEach { dict[$0] = [] }
        return dict
    }
    
    func fetchPosts(category: CommunitySectionType) -> Single<[CommunityModel]> {
        let collection = category.collectionName
        return FirestoreManager.shared.fetchCollection(
            collection: collection,
            sortField: "postDate",
            descending: true,
            type: CommunityModel.self
        )
        .flatMap { [weak self] data in
            guard let self else { return .just([]) }
            return self.fetchProfiles(data)
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        .observe(on: MainScheduler.instance)
    }
    
    func fetchProfiles(_ data: [CommunityModel]) -> Single<[CommunityModel]> {
        let singles = data.map { postData in
            let human = FirestoreManager.shared.fetchHumanProfile(userId: postData.userId)
            let pet   = FirestoreManager.shared.fetchUserPetProfiles(userId: postData.userId)
            return Single.zip(human, pet)
                .map { human, pet in
                    var post = postData
                    post.name = human.nickname
                    post.profileImage = human.image
                    post.petProfile = pet
                    return post
                }
        }
        return Single.zip(singles)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
    }
    
    func findPostId(section: CommunitySectionType, postCode: String) -> Single<String> {
        FirestoreManager.shared.findDocumentId(
            collection: section.collectionName,
            whereField: "postCode",
            isEqualTo: postCode
        )
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        .map { $0.first ?? "" }
    }
}
