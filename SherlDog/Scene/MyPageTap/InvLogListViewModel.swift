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
    var originalData = [WalkResult]()
    private var data = [WalkResultToList]()
    
    enum Input {
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
        fetchWalkResultData()
    }
    
}

// MARK: - Method
extension InvLogListViewModel {
    
    private func transform() {
        self.input
            .bind(onNext: { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .delete(let index):
                    self.deleteWalkResultData(at: index)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchWalkResultData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        self.data = []
        
        FirestoreManager.shared.fetchDocuments(collection: "WalkResult",
                                               whereField: "userId",
                                               isEqualTo: userId,
                                               type: WalkResult.self)
        .subscribe(onSuccess: { [weak self] result in
            guard let self else { return }
            
            result.forEach {
                self.originalData.append($0)
                self.data.append(WalkResultToList(from: $0))
            }
            
            self.output.cellData.accept([InvLogListDataSource(model: "", items: self.data)])
        })
        .disposed(by: disposeBag)
    }
    
    private func deleteWalkResultData(at indexPath: IndexPath) {
        self.originalData[indexPath.row]
        
        FirestoreManager.shared.deleteDocument(collection: "WalkResult",
                                               documentId: "") // todo: 도큐먼트 아이디,,?
        .subscribe(onCompleted: { [weak self] in
            self?.output.deleteCompleted.accept(())
        })
        .disposed(by: disposeBag)
    }
    
}
