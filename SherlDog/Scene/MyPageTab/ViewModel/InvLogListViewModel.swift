//
//  InvLogListViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 6/25/25.
//

import UIKit
import RxSwift
import RxRelay
import RxDataSources
import Differentiator
import FirebaseAuth
import FirebaseFirestore

// MARK: - InvLogListViewModel
class InvLogListViewModel {
    
    typealias InvLogListDataSource = SectionModel<String, WalkResultToList>
    
    private let disposeBag = DisposeBag()
    private var data = [WalkResultToList]() {
        didSet {
            self.output.cellData.accept([InvLogListDataSource(model: "", items: self.data)])
        }
    }
    var originalData = [WalkResult]()
    
    enum Input {
        case viewWillAppear
        case delete(IndexPath)
    }
    
    struct Output {
        let cellData = BehaviorRelay<[InvLogListDataSource]>(value: [])
        let deleteCompleted = PublishRelay<Void>()
    }
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    // MARK: - Initialize
    init() {
        transform()
    }
    
}

// MARK: - Method
extension InvLogListViewModel {
    
    private func transform() {
        self.input
            .bind(onNext: { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .viewWillAppear:
                    self.fetchWalkResultData()
                    
                case .delete(let index):
                    self.deleteWalkResultData(at: index)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchWalkResultData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        self.data = []
        self.originalData = []
        
        FirestoreManager.shared.fetchQuery(
            FirestoreQuery<WalkResult>(
                collection: .walkResult,
                type: .whereField(field: "userId", value: userId)
                )
        )
        .subscribe(onSuccess: { [weak self] walkResult in
            guard let self = self else { return }
            
            // 클라이언트에서 정렬
            let sortedResult = walkResult.sorted {
                $0.createdAt.dateValue() > $1.createdAt.dateValue()
            }
            
            self.originalData = sortedResult
            self.data = sortedResult.enumerated().map { index, result in
                let caseNumber = sortedResult.count - index  // 최신이 큰 번호
                return WalkResultToList(from: result, caseNumber: caseNumber)
            }
        })
        .disposed(by: disposeBag)
    }
    
    private func deleteWalkResultData(at indexPath: IndexPath) {
        FirestoreManager.shared.findDocumentId(collection: .walkResult,
                                               whereField: "walkingPathImage",
                                               isEqualTo: self.originalData[indexPath.row].walkingPathImage)
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        .flatMapCompletable { documentId in
            guard let id = documentId.first else { return Completable.error(FirestoreError.noData) }
            
            return FirestoreManager.shared.deleteDocument(collection: .walkResult, documentId: id)
                .andThen(FirebaseImageManager.shared.deleteImageByURL(self.originalData[indexPath.row].walkingPathImage))
        }
        .subscribe(onCompleted: { [weak self] in
            guard let self else { return }
            
            self.data.remove(at: indexPath.row)
            self.originalData.remove(at: indexPath.row)
            
            self.output.deleteCompleted.accept(())
        })
        .disposed(by: disposeBag)
    }
}
