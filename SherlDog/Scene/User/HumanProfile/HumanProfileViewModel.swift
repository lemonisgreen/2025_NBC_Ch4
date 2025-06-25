//
//  HumanProfileViewModel.swift
//  SherlDog
//

import Foundation
import FirebaseAuth
import Firebase
import RxSwift
import RxRelay
import UIKit

final class HumanProfileViewModel {
    let nickname = BehaviorRelay<String>(value: "")
    let introduce = BehaviorRelay<String>(value: "")
    let image = BehaviorRelay<UIImage?>(value: nil)
    let saveResult = PublishSubject<Result<Void, Error>>()
    let isLoading = PublishRelay<Bool>()

    private let disposeBag = DisposeBag()

    func uploadAndSaveProfile() {
        guard let image = image.value,
              !nickname.value.isEmpty,
              !introduce.value.isEmpty,
              let userId = Auth.auth().currentUser?.uid else {
            saveResult.onNext(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "입력값이 부족합니다."])))
            return
        }

        isLoading.accept(true)
        
        FirebaseImageManager.shared.uploadImage(image, type: .assistant) { [weak self] result in
            switch result {
            case .success(let imageURL):
                let data: [String: String] = [
                    "nickname": self?.nickname.value ?? "",
                    "image": imageURL,
                    "introduce": self?.introduce.value ?? ""
                ]
                
                FirestoreManager.shared.createDocument(
                    collection: "HumanProfile",
                    data: data,
                    documentId: userId
                ).subscribe(
                    onCompleted: {
                        DispatchQueue.main.async {
                            self?.isLoading.accept(false)
                            self?.saveResult.onNext(.success(()))
                        }
                    },
                    onError: { error in
                        DispatchQueue.main.async {
                            self?.isLoading.accept(false)
                            self?.saveResult.onNext(.failure(error))
                        }
                    }
                ).disposed(by: self?.disposeBag ?? DisposeBag())

            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isLoading.accept(false)
                    self?.saveResult.onNext(.failure(error))
                }
            }
        }
    }
}
