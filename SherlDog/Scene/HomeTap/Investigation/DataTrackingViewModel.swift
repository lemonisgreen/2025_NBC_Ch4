//
//  DataTrackingViewModel.swift
//  SherlDog
//
//  Created by 전원식 on 6/17/25.
//
import UIKit
import RxSwift
import RxCocoa
import CoreMotion
import FirebaseFirestore
import FirebaseAuth

class DataTrackingViewModel {
    let disposeBag = DisposeBag()
    let requestViewModel = PictureUploadRequestViewModel()
    let imageURL = BehaviorRelay<String>(value: "")
    var imageDocumentId: String = ""
    
    let numberOfSteps = BehaviorRelay<Int>(value: 0)
    let distance = BehaviorRelay<Double>(value: 0.0)
    let startDate = BehaviorRelay<Date?>(value: nil)
    let endDate = BehaviorRelay<Date?>(value: nil)
    let duration = BehaviorRelay(value: "")
    let trackingActive = BehaviorRelay<Bool>(value: false)
    let fullScreenImage = BehaviorRelay(value: UIImage())
    let capturedImage = PublishRelay<UIImage>()
    
    let saveResult = PublishSubject<Result<Void, Error>>()
    
    private let pedometer = CMPedometer()
    
    func startTracking() {
        let now = Date()
        startDate.accept(now)
        trackingActive.accept(true)
        
        pedometer.startUpdates(from: now) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            
            self.numberOfSteps.accept(data.numberOfSteps.intValue)
            self.distance.accept(data.distance?.doubleValue ?? 0.0)
        }
    }
    
    func stopTracking() {
        trackingActive.accept(false)
        pedometer.stopUpdates()
        endDate.accept(Date())
    }
    
    func saveWalkResultCapturedImage(image: UIImage, selectedProfiles: [PetProfile]) {
        FirebaseImageManager.shared.uploadImage(image, type: .walkResult) { [weak self] result in
            switch result {
            case .success(let urlString):
                self?.imageURL.accept(urlString)
                self?.saveWalkResult(selectedProfiles: selectedProfiles)
            case .failure(let error):
                self?.saveResult.onNext(.failure(error))
            }
        }
    }
    
    func saveWalkResult(selectedProfiles: [PetProfile]) {
        let dateString: String = {
            if let date = endDate.value {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: date)
            } else {
                return ""
            }
        }()
        
        let userId = Auth.auth().currentUser?.uid ?? "anonymous"
        let profileIds = selectedProfiles.map { $0.petProfileId }
        
        let newWalkResult = WalkResult(
            userId: userId,
            petProfileId: profileIds,
            date: dateString,
            distance: distance.value,
            duration: duration.value,
            steps: numberOfSteps.value,
            walkingPathImage: imageURL.value
        )
        
        FirestoreManager.shared.createDocument(
            collection: "WalkResult",
            data: newWalkResult)
        .subscribe(
            onCompleted: { [weak self] in
                self?.saveResult.onNext(.success(()))
            },
            onError: { [weak self] error in
                self?.saveResult.onNext(.failure(error))
            }
        )
        .disposed(by: disposeBag)
    }
}

