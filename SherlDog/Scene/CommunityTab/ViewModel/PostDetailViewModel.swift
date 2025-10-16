//
//  PostDetailViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 9/30/25.
//

import RxSwift
import RxCocoa
import RxDataSources
import Differentiator
import FirebaseAuth
import FirebaseFirestore

enum CommentEvent {
    case refresh
    case create(String)
    case fix(documentId: String, content: String)
    case delete(String)
    case block(String)
    case report(String)
    case error
}

final class PostDetailViewModel {
    
    struct Input {
        let refreshPost: Observable<Void>
        let likeEvent: Observable<Void>
        let commentEvent: Observable<CommentEvent>
        let postMenuEvent: Observable<PostMenuEvent>
    }
    
    struct Output {
        let postData: Driver<[postDataSource]>
        let commentData: Driver<[commentDataSource]>
        let isUpdating: Driver<Bool>
    }
    
    typealias postDataSource = SectionModel<CommunityModel, String>
    typealias commentDataSource = SectionModel<String, CommentModel>
    
    private let originalPost: CommunityModel
    private lazy var category: FirestoreCollection = {
        FirestoreCollection.allCases.filter {
            $0.rawValue == self.originalPost.category
        }.first ?? .invLogBoard
    }()
    private let disposeBag = DisposeBag()
    
    init(post: CommunityModel) {
        self.originalPost = post
    }
    
    func transform(_ input: Input) -> Output {
        let sharedRefresh = input.refreshPost.share()
        let commentRefreshTrigger = Observable.merge(
            input.commentEvent,
            sharedRefresh.map { CommentEvent.refresh }
        ).share()
        
        let postData = fetchPost(sharedRefresh)
        let commentData = commentEvent(commentRefreshTrigger)
        
        let refreshTrigger = Observable.merge(
            sharedRefresh,
            commentRefreshTrigger.map { _ in }
        )
        
        let fetchStream = Observable.merge(
            postData.map { _ in }.asObservable(),
            commentData.map { _ in }.asObservable()
        )
        
        let isUpdating = self.isUpdating(start: refreshTrigger,
                                         end: fetchStream)
        
        return Output(
            postData: postData,
            commentData: commentData,
            isUpdating: isUpdating
        )
    }
}

extension PostDetailViewModel {
    private func isUpdating(
        start: Observable<Void>,
        end: Observable<Void>
    ) -> Driver<Bool> {
        return Observable.merge(
            start.map { true },
            end.map { false }
        )
        .startWith(false)
        .distinctUntilChanged()
        .asDriver(onErrorJustReturn: false)
    }
    
    private func fetchPost(
        _ input: Observable<Void>
    ) -> Driver<[postDataSource]> {
        input
            .flatMap { [weak self] _ -> Observable<[postDataSource]> in
                guard let self else { return .empty() }
                
                return FirestoreManager.shared.fetchQuery(FirestoreQuery<CommunityModel>(
                    collection: self.category,
                    type: .document(id: self.originalPost.documentId)
                ))
                .flatMap { [weak self] data in
                    guard let self, let data = data.first else { return .just([]) }
                    
                    return self.fetchProfiles(data)
                        .map { [postDataSource(model: $0, items: $0.contentImage)] }
                }
                .asObservable()
            }
            .asDriver(onErrorDriveWith: .empty())
    }
    
    private func fetchProfiles(_ data: CommunityModel) -> Single<CommunityModel> {
        let pets = data.petProfile.map { pet in
            FirestoreManager.shared.fetchQuery(FirestoreQuery<PetProfile>(
                collection: .petProfile,
                type: .document(id: pet.petProfileId)
            ))
            .flatMap { profile -> Single<PetProfile> in
                guard let profile = profile.first else { return .error(FirestoreError.noData) }
                return .just(profile)
            }
        }
        
        let human = FirestoreManager.shared.fetchQuery(FirestoreQuery<HumanProfileModel>(
            collection: .humanProfile,
            type: .document(id: data.userId)
        ))
            .flatMap { profile -> Single<HumanProfileModel> in
                guard let profile = profile.first else { return .error(FirestoreError.noData) }
                return .just(profile)
            }
        
        let petZip = Single.zip(pets)
        
        return Single.zip(human, petZip)
            .map { human, pet in
                var post = data
                post.name = human.nickname
                post.profileImage = human.image
                post.petProfile = pet
                return post
            }
    }
    
    private func commentEvent(
        _ input: Observable<CommentEvent>
    ) -> Driver<[commentDataSource]> {
        return input
            .flatMap { [weak self] state -> Observable<CommentEvent> in
                guard let self,
                      let myUserId = Auth.auth().currentUser?.uid else { return .empty() }
                
                switch state {
                case .refresh:
                    return .just(state)
                    
                case let .create(content):
                    return FirestoreManager.shared.fetchQuery(
                        FirestoreQuery<HumanProfileModel>(
                            collection: .humanProfile,
                            type: .document(id: myUserId)
                        )
                    )
                    .flatMapCompletable { [weak self] humanProfile in
                        guard let self,
                              let humanProfile = humanProfile.first else { return .error(FirestoreError.unknown) }
                        
                        let data = CommentModel(
                            userId: myUserId,
                            user: humanProfile,
                            content: content,
                            date: Timestamp(date: Date())
                        )
                        
                        return CommunityActionManager.shared.createComment(collection: self.category,
                                                                           postCode: self.originalPost.documentId,
                                                                           data: data)
                        
                    }
                    .andThen(.just(state))
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                    
                case let .fix(documentId, content):
                    return CommunityActionManager.shared.updateComment(collection: self.category,
                                                                postCode: self.originalPost.documentId,
                                                                commentDocumentId: documentId,
                                                                text: content)
                    .andThen(.just(state))
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                    
                case let .delete(documentId):
                    return CommunityActionManager.shared.deleteComment(collection: self.category,
                                                                       postCode: self.originalPost.documentId,
                                                                       commentDocumentId: documentId)
                    .andThen(.just(state))
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))

                    
                case let .block(userId):
                    return BlockManager.shared.blockUser(userId)
                        .andThen(.just(state))
                        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))

                    
                case let .report(documentId):
                    let reportData = ReportModel(collection: "\(self.category.rawValue) -> \(self.originalPost.documentId)",
                                                 documentId: documentId)
                    
                    return FirestoreManager.shared.createDocument(collection: .reportLog,
                                                           data: reportData,
                                                           documentId: documentId)
                    .andThen(.just(state))
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                    
                case .error:
                    return .error(FirestoreError.unknown)
                }
            }
            .flatMap { _ in
                CommunityActionManager.shared.fetchCommentsList(collection: self.category,
                                                                postCode: self.originalPost.documentId)
            }
            .map { return [commentDataSource(model: SDLiteral.PostDetailViewController.commentHeaderTitle,
                                      items: $0)] }
            .asDriver(onErrorJustReturn: [])
    }
}
