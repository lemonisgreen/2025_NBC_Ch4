//
//  HumanProfileUploader.swift
//  SherlDog
//
//  Created by 최영락 on 6/20/25.
//

import RxSwift
import UIKit
import FirebaseAuth
import FirebaseStorage

class HumanProfileUploader {
    private let disposeBag = DisposeBag()

    func upload(nickname: String, image: UIImage, introduce: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(ImageError.invalidImageData))
            return
        }

        FirebaseImageManager.shared.uploadImage(image, type: .assistant) { result in
            switch result {
            case .success(let imageURL):
                let profile = HumanProfileModel(nickname: nickname, image: imageURL, introduce: introduce)

                FirestoreManager.shared.createDocument(
                    collection: "HumanProfile",
                    data: profile,
                    documentId: userId
                )
                .subscribe(
                    onCompleted: {
                        completion(.success(()))
                    },
                    onError: { error in
                        completion(.failure(error))
                    }
                )
                .disposed(by: self.disposeBag)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
