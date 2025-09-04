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
    
    let profileDidUpdate = PublishSubject<Void>()
    
    struct Input {
            let selectedImage = PublishRelay<UIImage?>()
            let name = BehaviorRelay<String>(value: "")
            let breed = BehaviorRelay<String>(value: "")
            let selectedSize = BehaviorRelay<String>(value: "")
            let selectedAge = BehaviorRelay<Date?>(value: nil)
            let selectedGender = BehaviorRelay<String>(value: "")
            let isNeutered = BehaviorRelay<Bool?>(value: nil)
            let introduce = BehaviorRelay<String>(value: "")
            let saveTrigger = PublishRelay<Void>() // 등록/수정 완료 버튼 탭
            
            // 편집 모드 설정
            let setEditProfile = PublishRelay<PetProfile>()
        }
    
    struct Output {
           let isLoading = BehaviorRelay<Bool>(value: false)
           let saveResult = PublishSubject<Result<Void, Error>>()
           let newPetProfileId = BehaviorSubject<String?>(value: nil)
           let editingProfile = PublishSubject<PetProfile>()
       }
    
    let imageURL = BehaviorRelay<String>(value: "")
    var imageDocumentId: String = ""
    // 편집 모드 관련 추가
    var currentMode: Mode = .create
    var editingProfileId: String?
    
    var buttonTitle: Observable<String> {
        return Observable.just(isEditMode() ? "수정완료" : "등록완료")
    }
    
    var titleText: Observable<String> {
        return Observable.just(isEditMode() ? "멍탐정 프로필 수정하기" : "멍탐정 프로필 등록하기")
    }

    enum Mode {
        case create
        case edit(PetProfile)
    }
    
    let input = Input()
    let output = Output()
    
    // 편집 모드 설정 함수
    func setEditMode(with profile: PetProfile) {
        currentMode = .edit(profile)
        editingProfileId = profile.petProfileId
        
        // 기존 데이터로 ViewModel 상태 설정
        input.name.accept(profile.name)
        input.breed.accept(profile.breed)
        input.selectedSize.accept(profile.size)
        input.selectedGender.accept(profile.gender)
        input.isNeutered.accept(profile.neutered)
        input.introduce.accept(profile.introduce)
        
        // 생년월일 설정 (날짜 포맷 헬퍼 사용)
        if let birthDate = stringToDate(profile.age) {
            input.selectedAge.accept(birthDate)
        }
    }
    
    // 현재 모드 확인 함수
    func isEditMode() -> Bool {
        switch currentMode {
        case .edit:
            return true
        case .create:
            return false
        }
    }
    
    // 날짜 포맷 헬퍼 함수들
    private func formatDateToString(_ date: Date?) -> String {
        guard let date = date else { return "" }
        return DateFormatter.yyyyMMdd.string(from: date)
    }
    
    private func stringToDate(_ dateString: String) -> Date? {
        return DateFormatter.yyyyMMdd.date(from: dateString)
    }
    
    func uploadImageAndSaveProfile(image: UIImage) {
        self.output.isLoading.accept(true)
        
        let newDocRef = FirestoreManager.shared.db.collection("PetProfile").document()
        let petProfileID = newDocRef.documentID
        self.imageDocumentId = petProfileID
        
        FirebaseImageManager.shared.uploadImage(image, type: .petProfile, petId: petProfileID) { [weak self] result in
            switch result {
            case .success(let urlString):
                self?.output.newPetProfileId.onNext(petProfileID)
                self?.imageURL.accept(urlString)
                self?.savePetProfile(petProfileID: petProfileID)
            case .failure(let error):
                self?.output.saveResult.onNext(.failure(error))
                self?.output.isLoading.accept(false)
            }
        }
    }
    
    // 편집 모드용 이미지 업로드 및 프로필 업데이트
    func updateProfileWithImage(image: UIImage, originalProfile: PetProfile) {
        self.output.isLoading.accept(true)
        
        // 기존 프로필 ID 사용
        let petProfileID = originalProfile.petProfileId
        self.imageDocumentId = petProfileID
        
        FirebaseImageManager.shared.uploadImage(image, type: .petProfile, petId: petProfileID) { [weak self] result in
            switch result {
            case .success(let urlString):
                self?.imageURL.accept(urlString)
                self?.updatePetProfile(petProfileID: petProfileID, originalProfile: originalProfile)
            case .failure(let error):
                self?.output.saveResult.onNext(.failure(error))
                self?.output.isLoading.accept(false)
            }
        }
    }
    
    func savePetProfile(petProfileID: String) {
        guard let isNeutered = input.isNeutered.value else { return }
        
        // 날짜 포맷 헬퍼 사용
        let dateString = formatDateToString(input.selectedAge.value)
        
        let userId = Auth.auth().currentUser?.uid ?? "anonymous"
        
        let newProfile = PetProfile(
            petProfileId: petProfileID,
            userId: userId,
            name: input.name.value,
            age: dateString,
            size: input.selectedSize.value,
            image: imageURL.value,
            gender: input.selectedGender.value,
            neutered: isNeutered,
            breed: input.breed.value,
            introduce: input.introduce.value,
            createdAt: Timestamp(date: Date())
        )
        
        FirestoreManager.shared.createDocument(
            collection: .petProfile,
            data: newProfile,
            documentId: petProfileID
        )
        .subscribe(
            onCompleted: { [weak self] in
                self?.output.newPetProfileId.onNext(petProfileID)
                self?.output.saveResult.onNext(.success(()))
                self?.output.isLoading.accept(false)
            },
            onError: { [weak self] error in
                self?.output.saveResult.onNext(.failure(error))
                self?.output.isLoading.accept(false)
            }
        )
        .disposed(by: disposeBag)
    }
    
    // 기존 프로필 업데이트 함수
    func updatePetProfile(petProfileID: String, originalProfile: PetProfile) {
        guard let isNeutered = input.isNeutered.value else { return }
        
        // 날짜 포맷 헬퍼 사용
        let dateString = formatDateToString(input.selectedAge.value)
        
        let updatedProfile = PetProfile(
            petProfileId: petProfileID,
            userId: originalProfile.userId,
            name: input.name.value,
            age: dateString,
            size: input.selectedSize.value,
            image: imageURL.value,
            gender: input.selectedGender.value,
            neutered: isNeutered,
            breed: input.breed.value,
            introduce: input.introduce.value,
            createdAt: originalProfile.createdAt
        )
        
        FirestoreManager.shared.updateDocument(
            collection: .petProfile,
            documentId: petProfileID,
            data: updatedProfile
        )
        .subscribe(
            onCompleted: { [weak self] in
                self?.output.editingProfile.onNext(updatedProfile)
                self?.output.saveResult.onNext(.success(()))
                self?.profileDidUpdate.onNext(())
                self?.output.isLoading.accept(false)
            },
            onError: { [weak self] error in
                self?.output.saveResult.onNext(.failure(error))
                self?.output.isLoading.accept(false)
            }
        )
        .disposed(by: disposeBag)
    }
}
