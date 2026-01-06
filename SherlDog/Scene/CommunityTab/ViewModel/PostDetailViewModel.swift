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
    case create(content: String, isSecret: Bool)
    case fix(documentId: String, content: String)
    case delete(String)
    case block(String)
    case report(documentId: String, userId: String)
    case error
}

enum PostDetailSectionModelType {
    case post(CommunityModel)
    case comment(String)
}

enum PostDetailItem {
    case post(String)
    case comment(CommentModel)
}

final class PostDetailViewModel {
    struct Input {
        let refreshPost: Observable<Void>
        let likeEvent: Observable<Void>
        let commentEvent: Observable<CommentEvent>
        let postMenuEvent: Observable<PostMenuEvent>
    }
    
    struct Output {
        let postDetailData: Driver<[PostDetailSectionModel]>
        let isUpdating: Driver<Bool>
        let showReport: Signal<ReportViewModel.Target>
    }
    
    typealias PostDetailSectionModel = SectionModel<PostDetailSectionModelType, PostDetailItem>
    
    private let originalPost: CommunityModel
    private lazy var category: FirestoreCollection = {
        FirestoreCollection(rawValue: originalPost.category) ?? .invLogBoard
    }()
    private let showReportSubject = PublishSubject<ReportViewModel.Target>()
    private let disposeBag = DisposeBag()
    
    init(post: CommunityModel) {
        self.originalPost = post
    }
    
    func transform(_ input: Input) -> Output {
        let sharedRefresh = input.refreshPost
            .startWith(())
            .share(replay: 1)
        let commentRefreshTrigger = Observable.merge(
            input.commentEvent,
            sharedRefresh.map { CommentEvent.refresh }
        ).share()
        
        let postData = fetchPost(sharedRefresh)
            .share(replay: 1)
        let commentData = commentEvent(commentRefreshTrigger)
            .startWith(SectionModel(model: .comment(SDLiteral.PostDetailViewController.commentHeaderTitle), items: []))
            .share(replay: 1)
        
        let postDetailData = Observable
            .combineLatest(postData, commentData) { [$0, $1] }
            .asDriver(onErrorJustReturn: [])
        
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
        
        input.postMenuEvent
            .subscribe(onNext: { [weak self] event in
                guard let self else { return }
                
                switch event {
                case let .report(documentId):
                    let target = ReportViewModel.Target.post(
                        collection: self.category,
                        documentId: documentId,
                        postUserId: self.originalPost.userId
                    )
                    self.showReportSubject.onNext(target)
                    
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
        
        let showReport = showReportSubject
            .asSignal(onErrorSignalWith: .empty())
        
        return Output(
            postDetailData: postDetailData,
            isUpdating: isUpdating,
            showReport: showReport
        )
    }
    
    func isWriter(_ writerUserId: String) -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        
        return writerUserId == currentUserId
    }
    
    func isPosterOrCommenter(commentUserId: String) -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        
        return self.originalPost.userId == currentUserId || commentUserId == currentUserId
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
    ) -> Observable<PostDetailSectionModel> {
        input
            .flatMap { [weak self] _ -> Observable<PostDetailSectionModel> in
                guard let self else { return .empty() }
                
                return FirestoreManager.shared.fetchQuery(FirestoreQuery<CommunityModel>(
                    collection: self.category,
                    type: .document(id: self.originalPost.documentId)
                ))
                .asObservable()
                .flatMap { [weak self] data -> Observable<PostDetailSectionModel> in
                    guard let self, let data = data.first else { return .empty() }
                    
                    return self.fetchProfiles(data)
                        .map { post in
                            let item = data.contentImage.map { PostDetailItem.post($0) }
                            let model: SectionModel<PostDetailSectionModelType, PostDetailItem> = SectionModel(
                                model: .post(post),
                                items: item
                            )
                            
                            return model
                        }
                        .asObservable()
                }
            }
    }
    
    private func fetchProfiles(_ data: CommunityModel) -> Single<CommunityModel> {
        let pets = data.petProfile.map { pet in
            FirestoreManager.shared.fetchQuery(FirestoreQuery<PetProfile>(
                collection: .petProfile,
                type: .document(id: pet.petProfileId)
            ))
            .flatMap { profile -> Single<PetProfile?> in
                return .just(profile.first)
            }
            .catchAndReturn(nil)
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
                post.petProfile = pet.compactMap { $0 }
                
                return post
            }
    }
    
    private func commentEvent(
        _ input: Observable<CommentEvent>
    ) -> Observable<PostDetailSectionModel> {
        return input
            .flatMap { [weak self] state -> Observable<CommentEvent> in
                guard let self,
                      let myUserId = Auth.auth().currentUser?.uid else { return .empty() }
                
                switch state {
                case .refresh:
                    return .just(state)
                    
                case let .create(content, isSecret):
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
                            date: Timestamp(date: Date()),
                            isSecret: isSecret
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
                    
                    
                case let .report(documentId, userId):
                    let target = ReportViewModel.Target.post(
                        collection: self.category,
                        documentId: documentId,
                        postUserId: userId
                    )
                    self.showReportSubject.onNext(target)
                    
                    return .just(state)
                    
                case .error:
                    return .error(FirestoreError.unknown)
                }
            }
            .flatMap { _ in
                CommunityActionManager.shared.fetchCommentsList(collection: self.category,
                                                                postCode: self.originalPost.documentId)
            }
            .map {
                let item = $0.map { PostDetailItem.comment($0) }
                let comment: SectionModel<PostDetailSectionModelType, PostDetailItem> = SectionModel(
                    model: .comment(SDLiteral.PostDetailViewController.commentHeaderTitle),
                    items: item
                )
                
                return comment
            }
    }
}
