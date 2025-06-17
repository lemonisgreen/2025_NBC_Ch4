//
//  RegistrationViewModel.swift
//  SherlDog
//
//  Created by JIN LEE on 6/16/25.
//

import RxSwift
import FirebaseFirestore
import RxRelay

class RegistrationViewModel {
    let db = Firestore.firestore()
    let disposeBag = DisposeBag()
    
    let imageURL = BehaviorRelay<String>(value: "")
    let name = BehaviorRelay<String>(value: "")
    let breed = BehaviorRelay<String>(value: "")
    let selectedSize = BehaviorRelay<String>(value: "")
    let selectedAge = BehaviorRelay<Date?>(value: nil)
    let selectedGender = BehaviorRelay<String>(value: "")
    let isNeutered = BehaviorRelay<Bool>(value: false)
    let introduce = BehaviorRelay<String>(value: "")
    
    let saveResult = PublishSubject<Result<Void, Error>>()
    
    //func savePetProfile(userID: String) {
    func savePetProfile() {
        let newDocument = db.collection("PetProfile").document()
        let ageTimestamp = Timestamp(date: selectedAge.value ?? Date())

        let documentData: [String: Any] = [
            //"userId": userID,
            "docID" : newDocument.documentID,
            "name": name.value,
            "age": ageTimestamp,
            "size": selectedSize.value,
            //"image": imageURL.value,
            "gender": selectedGender.value,
            "neutered": isNeutered.value,
            "breed": breed.value,
            "introduce": introduce.value
        ]
        
        newDocument.setData(documentData) { [weak self] error in
            if let error = error {
                self?.saveResult.onNext(.failure(error))
            } else {
                self?.saveResult.onNext(.success(()))
            }
        }
    }
}
