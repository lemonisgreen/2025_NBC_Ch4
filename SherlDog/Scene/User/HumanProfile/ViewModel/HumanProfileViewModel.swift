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
    
    enum Mode {
        case create
        case edit(HumanProfileModel)
    }
    
    let nickname = BehaviorRelay<String>(value: "")
    let introduce = BehaviorRelay<String>(value: "")
    let imageString = BehaviorRelay<String>(value: "")
    
    private let originalNickname = BehaviorRelay<String>(value: "")
    private let originalIntroduce = BehaviorRelay<String>(value: "")
    private let originalImageString = BehaviorRelay<String>(value: "")
    
    let imageForUpload = BehaviorRelay<UIImage?>(value: nil)
    let saveResult = PublishSubject<Result<Void, Error>>()
    let isLoading = PublishRelay<Bool>()
    
    var currentMode: Mode = .create
    let isEditMode = BehaviorRelay<Bool>(value: false)
    let userId = AuthSession.currentAppUserId
    private let disposeBag = DisposeBag()
    
    func setEditMode(with profile: HumanProfileModel) {
        currentMode = .edit(profile)
        isEditMode.accept(true)
        
        originalNickname.accept(profile.nickname)
        originalIntroduce.accept(profile.introduce)
        originalImageString.accept(profile.image)
        
        nickname.accept(profile.nickname)
        introduce.accept(profile.introduce)
        self.imageString.accept(profile.image)
    }
    
    func setCreateMode() {
        currentMode = .create
        isEditMode.accept(false)
        
        originalNickname.accept("")
        originalIntroduce.accept("")
        originalImageString.accept("")
        
        nickname.accept("")
        introduce.accept("")
        imageString.accept("")
    }
    
    func saveProfile() {
        switch currentMode {
        case .create:
            uploadAndSaveProfile()
        case .edit:
            updateProfile()
        }
    }
    
    var isSaveEnabled: Observable<Bool> {
        return Observable
            .combineLatest(
                nickname.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
                introduce.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
                imageForUpload,
                originalNickname,
                originalIntroduce,
                isEditMode
            )
            .map { nick, intro, newImage, origNick, origIntro, isEdit in
                guard !nick.isEmpty, !intro.isEmpty else { return false }
                
                if isEdit {
                    let textChanged = (nick != origNick) || (intro != origIntro)
                    let imageChanged = (newImage != nil)
                    return textChanged || imageChanged
                } else {
                    return newImage != nil
                }
            }
    }
    
    
    var nextButtonTitle: Observable<String> {
        return isEditMode.asObservable().map { isEdit in
            return isEdit ? "수정 완료" : "다음"
        }
    }
    
    var navigationTitle: Observable<String> {
        return isEditMode.asObservable().map { isEdit in
            return isEdit ? "조수 프로필 수정하기" : "조수 프로필 입력하기"
        }
    }
    
    func uploadAndSaveProfile() {
        guard let image = imageForUpload.value,
              !nickname.value.isEmpty,
              !introduce.value.isEmpty,
              let userId = AuthSession.currentAppUserId else {
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
                
                FirestoreManager.shared.createDocument(collection: .humanProfile, data: data, documentId: userId)
                    .subscribe(
                        onCompleted: { [weak self] in
                            DispatchQueue.main.async {
                                self?.isLoading.accept(false)
                                self?.saveResult.onNext(.success(()))
                            }
                        },
                        onError: { [weak self] error in
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
    
    func updateProfile() {
        guard case .edit(_) = currentMode,
              !nickname.value.isEmpty,
              !introduce.value.isEmpty,
              let userId = AuthSession.currentAppUserId else {
            saveResult.onNext(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "입력값이 부족합니다."])))
            return
        }
        
        isLoading.accept(true)
        
        if let image = imageForUpload.value {
            FirebaseImageManager.shared.uploadImage(image, type: .assistant) { [weak self] result in
                switch result {
                case .success(let imageURL):
                    let updatedProfile = HumanProfileModel(
                        nickname: self?.nickname.value ?? "",
                        image: imageURL,
                        introduce: self?.introduce.value ?? ""
                    )
                    
                    FirestoreManager.shared.updateDocument(collection: .humanProfile, documentId: userId, data: updatedProfile)
                        .subscribe(
                            onCompleted: { [weak self] in
                                DispatchQueue.main.async {
                                    self?.isLoading.accept(false)
                                    self?.saveResult.onNext(.success(()))
                                }
                            },
                            onError: { [weak self] error in
                                DispatchQueue.main.async {
                                    self?.isLoading.accept(false)
                                    self?.saveResult.onNext(.failure(error))
                                }
                            }
                        )
                        .disposed(by: self?.disposeBag ?? DisposeBag())
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.isLoading.accept(false)
                        self?.saveResult.onNext(.failure(error))
                    }
                }
            }
        } else if imageString.value != "" {
            let updatedProfile = HumanProfileModel(
                nickname: self.nickname.value,
                image: imageString.value,
                introduce: self.introduce.value
            )
            
            FirestoreManager.shared.updateDocument(collection: .humanProfile, documentId: userId, data: updatedProfile)
                .subscribe(onCompleted: { [weak self] in
                    DispatchQueue.main.async {
                        self?.isLoading.accept(false)
                        self?.saveResult.onNext(.success(()))
                    }
                }, onError: { [weak self] error in
                    DispatchQueue.main.async {
                        self?.isLoading.accept(false)
                        self?.saveResult.onNext(.failure(error))
                    }
                })
                .disposed(by: self.disposeBag)
        } else {
            saveResult.onNext(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "입력값이 부족합니다."])))
            return
        }
    }
}
