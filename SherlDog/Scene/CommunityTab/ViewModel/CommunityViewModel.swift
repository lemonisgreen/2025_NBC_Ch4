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

final class CommunityViewModel {
    
    // 게시판 종류
    enum CommunitySectionType: CaseIterable {
        case invLogBoard
        case detectiveMateBoard
        
        var name: String {
            switch self {
            case .invLogBoard:        return "수사 게시판"
            case .detectiveMateBoard: return "탐정 메이트"
            }
        }
        
        var collectionName: String {
            switch self {
            case .invLogBoard:        return "InvLogBoard"
            case .detectiveMateBoard: return "DetectiveMate"
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
    }
    
    struct Output {
        let selectedCategory: Driver<CommunitySectionType>
        let currentCellData: Driver<[CommunitySectionType: [CommunitySection]]>
        let isUpdating: Driver<Bool>
    }
    
    typealias CommunitySection = SectionModel<CommunityModel, String>
    
    private let disposeBag = DisposeBag()
    
    // MARK: Transform
    func transform(_ input: Input) -> Output {
        
        // 선택된 카테고리: 초기값 invLogBoard
        let selectedCategory = input.segmentIndexChanged
            .map { index -> CommunitySectionType in
                // 안전 접근을 위해 한 번 확인 후 접근
                CommunitySectionType.allCases.indices.contains(index)
                ? CommunitySectionType.allCases[index]
                : .invLogBoard
            }
            .startWith(.invLogBoard)
            .share(replay: 1)
        
        // 새로고침 트리거: 초기 로드 + 카테고리 변경 + Pull to refresh
        let refreshTrigger = Observable.merge(selectedCategory.map { _ in () },
                                              input.pullToRefresh)
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .share()
        
        // 트리거가 발생하면 데이터 패치
        let fetchStream = refreshTrigger
            .withLatestFrom(selectedCategory)
            .flatMapLatest { [weak self] category in
                guard let self else { return Observable<Event<[CommunityModel]>>.empty() }
                return self.fetchPosts(category: category)
                    .asObservable()
                    .materialize()
            }
            .share()
        
        let posts = fetchStream.compactMap { $0.element }
//        let postError = fetchStream.compactMap { $0.error }
        
        // 로딩 상태
        let isUpdating = Observable.merge(refreshTrigger.map { true },
                                          fetchStream.map { _ in false })
            .startWith(false)
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
        
        // Mutation - set
        let refreshMutation = posts
            .withLatestFrom(selectedCategory) { posts, category in
                return Mutation.set(category: category, posts: posts)
            }
            .asObservable()
        
        // Mutation - append
        let appendMutation = input.fetchMore
            .withLatestFrom(selectedCategory)
            .map { category -> Mutation in
                // TODO: 무한스크롤 구현
                return .append(category: category, posts: [])
            }
        
        let initialPosts = makeInitialPosts()
        
        let postsDict = Observable.merge(refreshMutation,
                                         appendMutation)
            .scan(initialPosts) { dict, mutation in
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
        
        let currentCellData = postsDict
            .map { dict in
                dict.mapValues { posts in
                    posts.map { CommunitySection(model: $0, items: $0.contentImage) }
                }
            }
            .asDriver(onErrorJustReturn: [:])
        
        return Output(
            selectedCategory: selectedCategory.asDriver(onErrorJustReturn: .invLogBoard),
            currentCellData: currentCellData,
            isUpdating: isUpdating
        )
    }
    
    // 초기 세팅: nil 방지
    private func makeInitialPosts() -> [CommunitySectionType : [CommunityModel]] {
        var dict: [CommunitySectionType: [CommunityModel]] = [:]
        CommunitySectionType.allCases.forEach { dict[$0] = [] }
        return dict
    }
    
    // MARK: - Networking helper
    private func fetchPosts(category: CommunitySectionType) -> Single<[CommunityModel]> {
        let collection = category.collectionName
        
        return FirestoreManager.shared.fetchCollection(
            collection: collection,
            sortField: "postDate",
            descending: true,
            type: CommunityModel.self
        )
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        .observe(on: MainScheduler.instance)
    }
}
