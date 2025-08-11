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

final class AddNewContentViewModel {
    
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
        let uploadComplete = PublishRelay<Void>()
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
                let ageGender = self.setAgeGenderStyle(data: profile)
                
                let uploadData = CommunityModel(profileImage: profile.image,
                                                name: profile.name,
                                                info: "\(ageGender) / \(profile.breed)",
                                                postDate: Timestamp(date: Date()),
                                                contentImage: urls,
                                                content: self.text.value)
                
                FirestoreManager.shared.createDocument(collection: "DetectiveMate", data: uploadData)
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                    .subscribe(onCompleted: { [weak self] in
                        guard let self else { return }
                        self.output.isLoading.accept(false)
                        self.output.uploadComplete.accept(())
                        
                    }, onError: { [weak self] error in
                        self?.output.error.accept(error.localizedDescription)
                        self?.output.isLoading.accept(false)
                        
                    })
                    .disposed(by: disposeBag)
            })
            .disposed(by: disposeBag)
    }
    
    private func uploadImage() -> Single<[String]> {
        let images = self.output.addedPictures.value
        
        let uploads: [Single<String>] = images.map { image in
            Single<String>.create { observer in
                FirebaseImageManager.shared.uploadImage(image, type: .detectiveMate) { [weak self] result in
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
    
    private func setAgeGenderStyle(data: PetProfile) -> String {
        let age = data.age
        let formatter = DateFormatter.yyyyMMdd
        guard let ageDate = formatter.date(from: age) else { return "알 수 없음" }
        
        return "\(ageFinder(dateOfBirth: ageDate)) \(genderFinder(gender: data.gender))"
    }
    
    private func ageFinder(dateOfBirth: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        
        if let year = components.year, year > 0 {
            return "\(year)세"
            
        } else if let month = components.month, month > 0 {
            return "\(month)개월"
            
        } else {
            return "신생아"
            
        }
    }
    
    private func genderFinder(gender: String) -> String {
        switch gender {
        case "male": return "남아"
        case "female": return "여아"
        default: return "알 수 없음"
        }
    }
}
