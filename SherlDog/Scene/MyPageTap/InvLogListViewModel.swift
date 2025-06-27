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
        
        FirestoreManager.shared.fetchDocuments(collection: "WalkResult",
                                               whereField: "userId",
                                               isEqualTo: userId,
                                               orderBy: "createdAt",
                                               type: WalkResult.self)
        .subscribe(onSuccess: { [weak self] result in
            guard let self else { return }
            
            self.originalData = result
            self.data = result.map { WalkResultToList(from: $0) }
        })
        .disposed(by: disposeBag)
    }
    
    private func deleteWalkResultData(at indexPath: IndexPath) {
        FirestoreManager.shared.findDocumentId(collection: "WalkResult",
                                               whereField: "walkingPathImage",
                                               isEqualTo: self.originalData[indexPath.row].walkingPathImage)
        .flatMapCompletable { documentId in
            guard let id = documentId.first else { return Completable.error(FirestoreError.noData) }
            
            return FirestoreManager.shared.deleteDocument(collection: "WalkResult", documentId: id)
                .andThen(FirebaseImageManager.shared.deleteImage(urlString: self.originalData[indexPath.row].walkingPathImage))
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
