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
    private var data: [WalkResultToList] = []
    
    enum Input {
        
    }
    
    struct Output {
        let cellData = BehaviorRelay<[InvLogListDataSource]>(value: [])
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
                self.data.append(WalkResultToList(from: $0))
            }
            
            self.output.cellData.accept([InvLogListDataSource(model: "", items: self.data)])
        })
        .disposed(by: disposeBag)
    }
    
}
