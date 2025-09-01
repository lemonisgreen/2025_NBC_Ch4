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
import PhotosUI

final class AddNewContentViewModel {
    
    enum Input {
        case addButtonTap
        case dropdownTap
        case profileSelect([Int])
        case addPicture
        case selectedPictures([PHPickerResult])
        case deleteButtonTap(Int)
    }
    
    struct Output {
        let petProfile = BehaviorRelay<[PetProfile]>(value: [])
//        let userProfile = BehaviorRelay<HumanProfileModel?>(value: nil)
        let selectedProfileIndex = BehaviorRelay<[Int]>(value: [])
        let selectedImageIdentifiers = BehaviorRelay<[String]>(value: [])
        let isLoading = BehaviorRelay<Bool>(value: false)
        let isExpended = BehaviorRelay<Bool?>(value: nil)
        let maxPictureCount: Int = 10
        let addPicture = PublishRelay<[String]>()
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
        fetchProfiles()
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
                    let ids = self.output.selectedImageIdentifiers.value
                    
                    self.output.addPicture.accept(ids)
                    
                case .selectedPictures(let results):
                    self.loadOrderedImages(from: results)
                        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                        .subscribe(onSuccess: { [weak self] images in
                            self?.output.addedPictures.accept(images)
                        })
                        .disposed(by: disposeBag)
                    
                case .deleteButtonTap(let row):
                    var images = self.output.addedPictures.value
                    var ids = self.output.selectedImageIdentifiers.value
                    images.remove(at: row)
                    ids.remove(at: row)
                    
                    self.output.addedPictures.accept(images)
                    self.output.selectedImageIdentifiers.accept(ids)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func loadOrderedImages(from results: [PHPickerResult]) -> Single<[UIImage]> {
        // 사진 고유 ID 추출
        let ids = results.compactMap { $0.assetIdentifier }
        guard !ids.isEmpty else { return .just([]) }
        self.output.selectedImageIdentifiers.accept(ids)
        print(ids)
        // ids 배열 순서대로 PHAsset을 담은 PHFetchResult 가져오기
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        
        // 사용자가 선택한 ID 순서대로 PHAsset 배열 복원
        var dics: [String: PHAsset] = [:]
          fetched.enumerateObjects { asset, _, _ in
              dics[asset.localIdentifier] = asset
          }
        
        let assetsInOrder = ids.compactMap { dics[$0] }
        
        // 각 PHAsset → 이미지 Single로 변환
        let imageSingles: [Single<UIImage?>] = assetsInOrder.map { asset in
            Single<UIImage?>.create { observer in
                let option = PHImageRequestOptions()
                option.isNetworkAccessAllowed = true
                option.deliveryMode = .highQualityFormat

                PHImageManager.default().requestImageDataAndOrientation(for: asset, options: option) { data, _, _, _ in
                    observer(.success(data.flatMap { UIImage(data: $0) }))
                }
                return Disposables.create()
            }
        }
        
        return Single.zip(imageSingles)
            .map { $0.compactMap { $0 } }   // nil 제거
    }
    
    private func addPost() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let selectedIndex = output.selectedProfileIndex.value
        let petProfiles = selectedIndex.map { self.output.petProfile.value[$0] }
        
        uploadImage()
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMapCompletable { [weak self] urls in
                guard let self else { return Completable.error(NSError(domain: "", code: 0, userInfo: nil)) }
                
                let uploadData = CommunityModel(userId: userId,
                                                postDate: Timestamp(date: Date()),
                                                contentImage: urls,
                                                content: self.text.value)
                
                return FirestoreManager.shared.createDocument(collection: "DetectiveMate", data: uploadData)
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            }
            .subscribe(onCompleted: { [weak self] in
                guard let self else { return }
                self.output.isLoading.accept(false)
                self.output.uploadComplete.accept(())
                
            }, onError: { [weak self] error in
                self?.output.error.accept(error.localizedDescription)
                self?.output.isLoading.accept(false)
            })
            .disposed(by: disposeBag)
    }
    
    private func uploadImage() -> Single<[String]> {
        let images = self.output.addedPictures.value
        
        let uploads: [Single<String>] = images.map { image in
            Single<String>.create { observer in
                FirebaseImageManager.shared.uploadDetectiveMateImage(image) { result in
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
    
    private func fetchProfiles() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
//        FirestoreManager.shared.fetchHumanProfile(userId: userId)
//            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
//            .subscribe(onSuccess: { [weak self] profile in
//                self?.output.userProfile.accept(profile)
//            })
//            .disposed(by: disposeBag)
        
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
