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

// MARK: - InvLogListViewModel
class InvLogListViewModel {
    
    typealias InvLogListDataSource = SectionModel<String, InvLogListModel>
    
    private let disposeBag = DisposeBag()
    
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
    }
    
}

// MARK: - Method
extension InvLogListViewModel {
    
    private func transform() {
        self.output.cellData.accept([InvLogListDataSource(model: "", items: InvLogListModel.sample)])
    }
    
}
