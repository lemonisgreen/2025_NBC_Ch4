//
//  RegistrationViewModel.swift
//  SherlDog
//
//  Created by JIN LEE on 6/16/25.
//

import RxSwift
import FirebaseFirestore
import RxRelay
import UIKit
import FirebaseAuth

class RegistrationViewModel {
    let disposeBag = DisposeBag()
    
    let imageURL = BehaviorRelay<String>(value: "")
    var imageDocumentId: String = ""
    
    let name = BehaviorRelay<String>(value: "")
    let breed = BehaviorRelay<String>(value: "")
    let selectedSize = BehaviorRelay<String>(value: "")
    let selectedAge = BehaviorRelay<Date?>(value: nil)
    let selectedGender = BehaviorRelay<String>(value: "")
    let isNeutered = BehaviorRelay<Bool?>(value: nil)
    let introduce = BehaviorRelay<String>(value: "")
    let isLoading = PublishRelay<Bool>()
    let saveResult = PublishSubject<Result<Void, Error>>()

    func uploadImageAndSaveProfile(image: UIImage) {
        self.isLoading.accept(true)
        
        let newDocRef = FirestoreManager.shared.db.collection("PetProfile").document()
        let petProfileID = newDocRef.documentID
        self.imageDocumentId = petProfileID
        
        FirebaseImageManager.shared.uploadPetImage(image, petId: petProfileID) { [weak self] result in
            switch result {
            case .success(let urlString):
                self?.imageURL.accept(urlString)
                self?.savePetProfile(petProfileID: petProfileID)
            case .failure(let error):
                self?.saveResult.onNext(.failure(error))
                self?.isLoading.accept(false)
            }
        }
    }
    func savePetProfile(petProfileID: String) {
        guard let isNeutered = isNeutered.value else { return }
        
        let dateString: String = {
            if let date = selectedAge.value {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: date)
            } else {
                return ""
            }
        }()
        
        let userId = Auth.auth().currentUser?.uid ?? "anonymous"
        
        let newProfile = PetProfile(
            petProfileId: petProfileID,
            userId: userId,
            name: name.value,
            age: dateString,
            size: selectedSize.value,
            image: imageURL.value,
            gender: selectedGender.value,
            neutered: isNeutered,
            breed: breed.value,
            introduce: introduce.value
        )
        
        FirestoreManager.shared.createDocument(
            collection: "PetProfile",
            data: newProfile,
            documentId: petProfileID
        )
        .subscribe(
            onCompleted: { [weak self] in
                UserDefaults.standard.set(petProfileID, forKey: "newPetProfileId")
                self?.saveResult.onNext(.success(()))
                self?.isLoading.accept(false)
            },
            onError: { [weak self] error in
                self?.saveResult.onNext(.failure(error))
                self?.isLoading.accept(false)
            }
        )
        .disposed(by: disposeBag)
    }
}
