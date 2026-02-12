//
//  PostFooterViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 9/16/25.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth

struct PostFooterLikeState {
    let likeImage: UIImage?
    let likeCountText: String
}

final class PostFooterViewModel {
    
    struct Input {
        let likeTap: Observable<Void>
    }
    
    struct Output {
        let state: Driver<PostFooterLikeState>
    }
    
    private let disposeBag = DisposeBag()
    
    private let post: CommunityModel
    private let category: FirestoreCollection
    
    init(category: FirestoreCollection, post: CommunityModel) {
        self.post = post
        self.category = category
    }
    
    func transform(input: Input) -> Output {
        let userId = AuthSession.currentAppUserId ?? ""
        
        let isLiked = CommunityActionManager.shared
            .observeIsLiked(collection: category,
                            postCode: post.documentId,
                            userId: userId)
            .distinctUntilChanged()
            .share(replay: 1)
        
        let likeCount = CommunityActionManager.shared
            .observeLikeCount(collection: category,
                              postCode: post.documentId)
            .distinctUntilChanged()
            .share(replay: 1)
        
        bindLikeSideEffect(input.likeTap)
        
        let state = Observable.combineLatest(isLiked, likeCount)
            .map { liked, count in
                PostFooterLikeState(
                    likeImage: liked
                    ? UIImage(systemName: "heart.fill")?.withTintColor(.keycolorPrimary2, renderingMode: .alwaysOriginal)
                    : UIImage(systemName: "heart")?.withTintColor(.gray900, renderingMode: .alwaysOriginal),
                    likeCountText: count > 0 ? "\(count)" : ""
                )
            }
            .asDriver(onErrorJustReturn: PostFooterLikeState(
                likeImage: UIImage(systemName: "heart"),
                likeCountText: ""))
        
        return Output(state: state)
    }
    
    private func bindLikeSideEffect(_ likeTap: Observable<Void>) {
        likeTap
            // DEBUG: verify tap travels into the VM
            .do(onNext: { [weak self] in
                guard let self else { return }
            })
            // prevent rapid double triggers from both cell + footer
            .throttle(.milliseconds(250), scheduler: MainScheduler.instance)
            .flatMapFirst { [weak self] _ -> Completable in
                guard let self else { return .empty() }
                return CommunityActionManager.shared.toggleLikeWithCount(
                    collection: self.category,
                    postCode: self.post.documentId
                )
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
}
