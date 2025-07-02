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

    var currentMode: Mode = .create
    let isEditMode = BehaviorRelay<Bool>(value: false)
    let userId = Auth.auth().currentUser?.uid
    private let disposeBag = DisposeBag()
    
    enum Mode {
        case create
        case edit(HumanProfileModel)
    }
    
    func setEditMode(with profile: HumanProfileModel) {
        currentMode = .edit(profile)
        isEditMode.accept(true)
        
        nickname.accept(profile.nickname)
        introduce.accept(profile.introduce)
        
        loadExistingImage(from: profile.image)
    }
    
    func setCreateMode() {
        currentMode = .create
        isEditMode.accept(false)
        
        nickname.accept("")
        introduce.accept("")
        image.accept(nil)
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
            .combineLatest(nickname, introduce, image)
            .map { nickname, introduce, image in
                return !nickname.isEmpty && !introduce.isEmpty && image != nil
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
    
    private func loadExistingImage(from imageUrl: String) {
        guard !imageUrl.isEmpty, let url = URL(string: imageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.image.accept(loadedImage)
                }
            }
        }.resume()
    }
    
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
    
    func updateProfile() {
        guard case .edit(let originalProfile) = currentMode,
              let image = image.value,
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
                let updatedProfile = HumanProfileModel(
                    nickname: self?.nickname.value ?? "",
                    image: imageURL,
                    introduce: self?.introduce.value ?? ""
                )
                
                FirestoreManager.shared.updateDocument(
                    collection: "HumanProfile",
                    documentId: userId,
                    data: updatedProfile
                )
                .subscribe(
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
                )
                .disposed(by: self?.disposeBag ?? DisposeBag())
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isLoading.accept(false)
                    self?.saveResult.onNext(.failure(error))
                }
            }
        }
    }
}
