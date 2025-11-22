//
//  ReportViewModel.swift
//  SherlDog
//
//  Created by Jin Lee on 11/22/25.
//

import Foundation
import RxSwift
import RxRelay
import FirebaseAuth
import FirebaseFirestore

final class ReportViewModel {
    
    enum Target {
        case post(collection: FirestoreCollection, documentId: String, postUserId: String)
        case user(userId: String)
    }
    
    struct Input {
        let submit: PublishRelay<(reason: String, detail: String)>
    }
    
    struct Output {
        let isLoading: BehaviorRelay<Bool>
        let submitSuccess: PublishRelay<Void>
        let submitError: PublishRelay<Error>
    }
    
    let input: Input
    let output: Output
    
    private let target: Target
    private let disposeBag = DisposeBag()
    
    init(target: Target) {
        self.target = target
        
        let submitRelay = PublishRelay<(reason: String, detail: String)>()
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        let successRelay = PublishRelay<Void>()
        let errorRelay = PublishRelay<Error>()
        
        self.input = Input(submit: submitRelay)
        self.output = Output(
            isLoading: isLoadingRelay,
            submitSuccess: successRelay,
            submitError: errorRelay
        )
        
        submitRelay
            .subscribe(onNext: { [weak self] reason, detail in
                guard let self else { return }
                
                isLoadingRelay.accept(true)
                
                let reporterId = Auth.auth().currentUser?.uid ?? "anonymous"
                let now = Date()
                
                let targetInfo: (collection: FirestoreCollection,
                                 targetUserId: String?,
                                 targetPostId: String?) = {
                    switch self.target {
                    case let .post(collection, documentId, postUserId):
                        return (collection, postUserId, documentId)
                    case let .user(userId):
                        return (.humanProfile, userId, nil)
                    }
                }()
                
                let report = ReportModel(
                    reporterId: reporterId,
                    targetUserId: targetInfo.targetUserId,
                    targetPostId: targetInfo.targetPostId,
                    targetCollection: targetInfo.collection.rawValue,
                    reason: reason,
                    detail: detail,
                    createdAt: Timestamp(date: now)
                )
                
                FirestoreManager.shared
                    .createDocument(
                        collection: .reportLog,
                        data: report
                    )
                    .subscribe(
                        onCompleted: {
                            isLoadingRelay.accept(false)
                            successRelay.accept(())
                        },
                        onError: { error in
                            isLoadingRelay.accept(false)
                            errorRelay.accept(error)
                        }
                    )
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }
}
