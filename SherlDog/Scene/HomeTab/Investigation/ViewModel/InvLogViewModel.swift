//
//  InvLogViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 6/18/25.
//

import RxSwift
import RxRelay
import UIKit
import FirebaseAuth
import FirebaseFirestore

class InvLogViewModel {
    
    struct UploadData {
        let invImage: UIImage
        let content: String
    }
    
    enum Input {
        case didFinishedWrite(UploadData)
    }
    
    struct Output {
        let isLoading = BehaviorRelay<Bool>(value: false)
        let uploadComplete = PublishRelay<Void>()
        let uploadError = PublishRelay<Void>()
        let humanProfile = BehaviorRelay<HumanProfileModel?>(value: nil)
        let petProfile = BehaviorRelay<[PetProfile]>(value: [])
    }
    
    private let disposeBag = DisposeBag()
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init() {
        fetchHumanProfile()
        fetchPetProfile()
        transform()
    }
    
    private func transform() {
        self.input
            .subscribe(onNext: { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .didFinishedWrite(let data):
                    self.output.isLoading.accept(true)
                    self.imageToString(data: data)
                    
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func upload(image: String, content: String) {
        guard let userId = Auth.auth().currentUser?.uid,
              let humanProfile = output.humanProfile.value else { return }
        let petProfile = output.petProfile.value
        let newDocRef = FirestoreManager.shared.db.collection(FirestoreCollection.invLogBoard.rawValue).document()
        let documentId = newDocRef.documentID
        
        let data = CommunityModel(category: FirestoreCollection.invLogBoard.rawValue,
                                  userId: userId,
                                  profileImage: humanProfile.image,
                                  name: humanProfile.nickname,
                                  petProfile: petProfile,
                                  postDate: Timestamp(date: Date()),
                                  contentImage: [image],
                                  content: content,
                                  documentId: documentId)
        
        FirestoreManager.shared.createDocument(collection: .invLogBoard,
                                               data: data,
                                               documentId: documentId)
        .subscribe(onCompleted: { [weak self] in
            self?.output.isLoading.accept(false)
            self?.output.uploadComplete.accept(())
        }, onError: { [weak self] _ in
            self?.output.isLoading.accept(false)
            self?.output.uploadError.accept(())
        })
        .disposed(by: disposeBag)
    }
    
    private func fetchHumanProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        FirestoreManager.shared.fetchQuery(FirestoreQuery<HumanProfileModel>(
            collection: .humanProfile,
            type: .document(id: userId)
        ))
        .flatMap { profile in
            guard let profile = profile.first else { return .error(FirestoreError.noData) }
            return .just(profile)
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        .subscribe(onSuccess: { [weak self] profile in
            self?.output.humanProfile.accept(profile)
        })
        .disposed(by: disposeBag)
    }
    
    private func fetchPetProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        FirestoreManager.shared.fetchQuery(FirestoreQuery<PetProfile>(
            collection: .petProfile,
            type: .whereField(field: SDLiteral.FirestoreFieldName.userId,
                              value: userId)
        ))
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        .subscribe(onSuccess: { [weak self] profile in
            self?.output.petProfile.accept(profile)
        })
        .disposed(by: disposeBag)
    }
    
    private func imageToString(data: UploadData) {
        FirebaseImageManager.shared.uploadImage(data.invImage, type: .invLogBoard) { [weak self] result in
            switch result {
            case .success(let value):
                self?.upload(image: value, content: data.content)
                
            case .failure(_):
                self?.output.isLoading.accept(false)
                self?.output.uploadError.accept(())
                return
            }
        }
    }
    
}
