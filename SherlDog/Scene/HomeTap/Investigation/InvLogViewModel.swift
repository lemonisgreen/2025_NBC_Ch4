//
//  InvLogViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 6/18/25.
//

import RxSwift
import RxRelay
import UIKit

class InvLogViewModel {
    
    enum Input {
        case shareButtonTap
    }
    
    struct InvLogData {
        let image: UIImage
        let content: String
    }
    
    private let disposeBag = DisposeBag()
    private let collection: String = "InvLog"
    
    let input = PublishRelay<Input>()
    let output = BehaviorRelay<InvLogData?>(value: nil)
    
    init() {
        transform()
    }
    
    private func transform() {
        self.input
            .subscribe(onNext: { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .shareButtonTap:
                    FirestoreManager.shared.createDocument(collection: collection, data: InvLogModel(userId: "",
                                                                                                     image: "",
                                                                                                     content: ""))
                    .subscribe(onCompleted: { [weak self] in
                        guard let self else { return }
                        
                        
                    }, onError: { error in
                        
                    })
                    .disposed(by: disposeBag)
                }
            })
            .disposed(by: disposeBag)
    }
    
}
