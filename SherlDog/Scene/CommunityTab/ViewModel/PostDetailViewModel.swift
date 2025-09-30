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
    case create(String)
    case fix(String)
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
        let postData: Driver<postDataSource>
        let commentData: Driver<commentDataSource>
    }
    
    typealias postDataSource = SectionModel<CommunityModel, String>
    typealias commentDataSource = SectionModel<String, CommentModel>
    
    private let originalPost: CommunityModel
    private let disposeBag = DisposeBag()
    
    init(post: CommunityModel) {
        self.originalPost = post
    }
    
    func transform(_ input: Input) -> Output {
        let collection = {
            FirestoreCollection.allCases.filter {
                $0.rawValue == self.originalPost.category
            }.first ?? .invLogBoard
        }()
        
        let sharedRefresh = input.refreshPost.share()
        let postData = fetchPost(sharedRefresh, collection: collection)
        let commentData = fetchComment(sharedRefresh, collection: collection)
        
        return Output(
            postData: postData,
            commentData: commentData
        )
    }
}

extension PostDetailViewModel {
    private func fetchPost(
        _ input: Observable<Void>,
        collection: FirestoreCollection
    ) -> Driver<postDataSource> {
        input
            .flatMap { [weak self] _ -> Observable<postDataSource> in
                guard let self else { return .empty() }
                
                return FirestoreManager.shared.fetchQuery(FirestoreQuery<CommunityModel>(
                    collection: collection,
                    type: .document(id: self.originalPost.documentId)
                ))
                .asObservable()
                .compactMap(\.first)
                .map { postDataSource(model: $0, items: $0.contentImage) }
            }
            .asDriver(onErrorDriveWith: .empty())
    }
    
    private func fetchComment(
        _ input: Observable<Void>,
        collection: FirestoreCollection
    ) -> Driver<commentDataSource> {
        input
            .flatMap { [weak self] _ -> Observable<commentDataSource> in
                guard let self else { return .empty() }
                
                return CommunityActionManager.shared.fetchCommentsList(collection: collection,
                                                                       postCode: self.originalPost.documentId)
                .asObservable()
                .map { commentDataSource(model: "", items: $0) }
            }
            .asDriver(onErrorDriveWith: .empty())
    }
}
