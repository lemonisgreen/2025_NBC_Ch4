//
//  AddNewContentViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 8/7/25.
//

import RxSwift
import RxRelay
import UIKit
import FirebaseFirestore
import FirebaseAuth

class AddNewContentViewModel {
    
    enum Input {
        case addButtonTap
        case dropdownTap
        case profileSelect(Int)
        case addPicture
        case selectedPictures(UIImage)
        case deleteButtonTap(Int)
    }
    
    struct Output {
        let petProfile = BehaviorRelay<[PetProfile]>(value: [])
        let selectedProfileIndex = BehaviorRelay<Int>(value: 0)
        let isLoading = BehaviorRelay<Bool>(value: false)
        let isExpended = BehaviorRelay<Bool?>(value: nil)
        let maxPictureCount: Int = 10
        let addPicture = PublishRelay<Int>()
        let addedPictures = BehaviorRelay<[UIImage]>(value: [])
        let error = PublishRelay<String>()
    }
    
    let text = BehaviorRelay<String>(value: "")
    
    private let disposeBag = DisposeBag()
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init() {
        transform()
        fetchPetProfile()
    }
    
    private func transform() {
        self.input
            .bind(onNext: { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .dropdownTap:
                    self.output.isExpended.accept(!(self.output.isExpended.value ?? false))
                    
                case .addButtonTap:
                    self.output.isLoading.accept(true)
                    self.addPost()
                    
                case .profileSelect(let row):
                    self.output.selectedProfileIndex.accept(row)
                    
                case .addPicture:
                    let maxCount = self.output.maxPictureCount
                    let nowCount = self.output.addedPictures.value.count
                    let pickable = max(maxCount - nowCount, 0)
                    
                    self.output.addPicture.accept(pickable)
                    
                case .selectedPictures(let image):
                    var images = self.output.addedPictures.value
                    images.append(image)
                    
                    self.output.addedPictures.accept(images)
                    
                case .deleteButtonTap(let row):
                    var images = self.output.addedPictures.value
                    images.remove(at: row)
                    
                    self.output.addedPictures.accept(images)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func addPost() {
        let selectedIndex = output.selectedProfileIndex.value
        let profile = self.output.petProfile.value[selectedIndex]
        
        uploadImage()
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onSuccess: { [weak self] urls in
                guard let self else { return }
                
                // TODO: 업로드 로직
            })
            .disposed(by: disposeBag)
        
//        CommunityModel(profileImage: profile.image,
//                       name: profile.name,
//                       info: "\(profile.age) / \(profile.gender)",
//                       postDate: Timestamp(date: Date()),
//                       contentImage: [],
//                       content: self.text.value)
    }
    
    private func uploadImage() -> Single<[String]> {
        let images = self.output.addedPictures.value
        
        let uploads: [Single<String>] = images.map { image in
            Single<String>.create { observer in
                FirebaseImageManager.shared.uploadImage(image, type: .detectiveMate) { [weak self] result in
                    guard let self else { return }
                    
                    switch result {
                    case .success(let imageUrl):
                        observer(.success(imageUrl))
                    case .failure(let error):
                        observer(.failure(error))
                    }
                }
                return Disposables.create()
            }
        }
        
        return Single.zip(uploads)
        
    }
    
    private func fetchPetProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        FirestoreManager.shared.fetchUserPetProfiles(userId: userId)
            .subscribe(onSuccess: { [weak self] profile in
                self?.output.petProfile.accept(profile)
            })
            .disposed(by: disposeBag)
    }
}
