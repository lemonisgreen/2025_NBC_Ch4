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
        let invImage: UIImage
        let content: String
    }
    
    enum Input {
        case didFinishedWrite(UploadData)
    }
    
    struct Output {
        let isLoading = BehaviorRelay<Bool>(value: false)
        let uploadComplete = PublishRelay<Void>()
        let uploadError = PublishRelay<Void>()
    }
    
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
                    self.output.isLoading.accept(true)
                    self.imageToString(data: data)
                    
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func upload(image: String, content: String) {
        FirestoreManager.shared.createDocument(collection: .invLog,
                                               data: InvLogModel(userId: "unknown", image: image, content: content)) // todo: Insert userId
        .subscribe(onCompleted: { [weak self] in
            self?.output.isLoading.accept(false)
            self?.output.uploadComplete.accept(())
        }, onError: { [weak self] _ in
            self?.output.isLoading.accept(false)
            self?.output.uploadError.accept(())
        })
        .disposed(by: disposeBag)
    }
    
    private func imageToString(data: UploadData) {
        FirebaseImageManager.shared.uploadInvLogImage(data.invImage) { [weak self] result in
            switch result {
            case .success(let value):
                self?.upload(image: value, content: data.content)
                
            case .failure(let error):
                self?.output.isLoading.accept(false)
                self?.output.uploadError.accept(())
                return
            }
        }
    }
    
}
