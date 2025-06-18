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
    
    func savePetProfile() {
        let newDocRef = FirestoreManager.shared.db.collection("PetProfile").document()
        let petProfileID = newDocRef.documentID
        
        // selectedAge값 스트링으로 변경
        let dateString: String
        if let date = selectedAge.value {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dateString = formatter.string(from: date)
        } else {
            dateString = "" // 혹은 nil 허용, 기본값 등
        }
        
        let newProfile = PetProfile(
            petProfileId: petProfileID,
            userId: "추후 입력",
            name: name.value,
            age: dateString,
            size: selectedSize.value,
            image: selectedGender.value,
            gender: selectedGender.value,
            neutered: isNeutered.value,
            breed: breed.value,
            introduce: introduce.value
        )
        
        // FirestoreManager를 통한 저장
        FirestoreManager.shared.createDocument(
            collection: "PetProfile",
            data: newProfile,
            documentId: petProfileID
        )
        .subscribe(
            onCompleted: { [weak self] in
                //petProfileID 유저 디폴트에 저장하기
                UserDefaults.standard.set(petProfileID, forKey: "newPetProfileId")
                self?.saveResult.onNext(.success(()))
            },
            onError: { [weak self] error in
                self?.saveResult.onNext(.failure(error))
            }
        )
        .disposed(by: disposeBag)
    }
}
