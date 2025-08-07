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

class AddNewContentViewModel {
    
    enum Input {
        case dropdownTap
        case addButtonTap
        case addPicture
        case selectedPictures(UIImage)
    }
    
    struct Output {
        let petProfile = BehaviorRelay<[PetProfile]>(value: [PetProfile(petProfileId: "",
                                                                        userId: "",
                                                                        name: "asd",
                                                                        age: "",
                                                                        size: "",
                                                                        image: "",
                                                                        gender: "",
                                                                        neutered: false,
                                                                        breed: "",
                                                                        introduce: "",
                                                                        createdAt: Timestamp(date: Date()))])
        let isLoading = BehaviorRelay<Bool>(value: false)
        let isExpended = BehaviorRelay<Bool?>(value: nil)
        let maxPictureCount: Int = 10
        let addPicture = PublishRelay<Int>()
        let addedPictures = BehaviorRelay<[UIImage]>(value: [])
    }
    
    private let disposeBag = DisposeBag()
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init() {
        transform()
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
                    
                case .addPicture:
                    let maxCount = self.output.maxPictureCount
                    let nowCount = self.output.addedPictures.value.count
                    let pickable = max(maxCount - nowCount, 0)
                    
                    self.output.addPicture.accept(pickable)
                    
                case .selectedPictures(let image):
                    var images = self.output.addedPictures.value
                    images.append(image)
                    
                    self.output.addedPictures.accept(images)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchPetProfile() {
        
    }
}
