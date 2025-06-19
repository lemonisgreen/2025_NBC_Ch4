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
    
    struct UploadData {
        let imageString: UIImage
        let content: String
    }
    
    enum Input {
        case didFinishedWrite(UploadData)
    }
    
    struct Output {
        let uploadComplete = PublishRelay<Void>()
    }
    
    private let collection: String = "InvLog"
    private let disposeBag = DisposeBag()
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init() {
        transform()
    }
    
    private func transform() {
        self.input
            .subscribe(onNext: { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .didFinishedWrite(let data):
                    self.imageToString(data: data)
                    
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func upload(image: String, content: String) {
        FirestoreManager.shared.createDocument(collection: self.collection, data: InvLogModel(userId: "", // todo: Insert userId
                                                                                              image: image,
                                                                                              content: content))
        .subscribe(onCompleted: {
            self.output.uploadComplete.accept(())
        })
        .disposed(by: disposeBag)
    }
    
    private func imageToString(data: UploadData) {
        // todo: Insert petId
        FirebaseImageManager.shared.uploadPetImage(data.imageString, petId: "") { [weak self] result in
            switch result {
            case .success(let value):
                self?.upload(image: value, content: data.content)
                
            case .failure(let error):
                return // todo: Error 처리
                
            }
        }
    }
    
}
