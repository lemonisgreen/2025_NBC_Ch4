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
    let fullScreenImage = PublishRelay<UIImage>()
    let capturedImage = PublishRelay<UIImage>()
    let walkingPathImageURL = BehaviorRelay<String>(value: "")
    
    let fetchResult = BehaviorRelay<WalkResult?>(value: nil)
    let saveResult = PublishSubject<Result<Void, Error>>()
    
    private let pedometer = CMPedometer()
    
    init() {
        transform()
    }
    
    private func transform() {
        self.fetchResult
            .subscribe(onNext: { [weak self] result in
                guard let self,
                      let result,
                      let date = DateFormatter.yyyyMMdd.date(from: result.date) else { return }

                self.numberOfSteps.accept(result.steps)
                self.distance.accept(result.distance)
                self.duration.accept(result.duration)
                self.endDate.accept(date)
                
                // 경로 이미지 URL 전달
                self.walkingPathImageURL.accept(result.walkingPathImage)
            })
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(startDate, endDate)
            .compactMap { start, end -> String? in
                guard let start = start, let end = end else { return nil }
                let interval = Int(end.timeIntervalSince(start))
                let hours = interval / 3600
                let minutes = (interval % 3600) / 60
                let seconds = interval % 60
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            }
            .bind(onNext: { [weak self] result in
                guard let self else { return }
                
                duration.accept(result)
            })
            .disposed(by: disposeBag)
    }
    
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
        FirebaseImageManager.shared.uploadWalkResultImage(image) { [weak self] result in
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
                return DateFormatter.yyyyMMdd.string(from: date)
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
            walkingPathImage: imageURL.value,
            createdAt: Timestamp(date: Date())
        )
        
        FirestoreManager.shared.createDocument(
            collection: .walkResult,
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

