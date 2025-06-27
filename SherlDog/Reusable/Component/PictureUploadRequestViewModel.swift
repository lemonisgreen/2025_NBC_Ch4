//
//  PictureUploadRequestViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 6/10/25.
//

import RxSwift
import RxRelay
import RxDataSources
import Differentiator
import FirebaseAuth
import FirebaseFirestore

class PictureUploadRequestViewModel {
    
    enum RequestSender {
        case pictureRequest
        case pictureRequestForAssistant
        case pictureRequestForPet
        case sherlDogRequest
        case sherlDogResult
    }
    
    enum MoveToView {
        case camera
        case album
        case avatar
    }
    
    struct CellList {
        let title: String
        let image: String
        let imageView: UIImageView?
        
        init(title: String, image: String, imageView: UIImageView? = nil) {
            self.title = title
            self.image = image
            self.imageView = imageView
        }
    }
    
    enum Input {
        case sender(RequestSender)
        case setButtonTapped([Int])
    }
    
    struct Output {
        let sender = BehaviorRelay<RequestSender?>(value: nil)
        let buttonName = BehaviorRelay<String>(value: "")
        let cellData = BehaviorRelay(value: [RequestDataSource]())
        let moveToView = PublishRelay<MoveToView>()
        let petIndex = PublishRelay<[Int]>()
        //펫프로필 받아오기
        let petProfiles = BehaviorRelay<[PetProfile]>(value: [])
        // 선택된 강아지 정보 저장
        let selectedPetProfiles = BehaviorRelay<[PetProfile]>(value: [])
    }
    
    typealias RequestDataSource = SectionModel<String, CellList>
    
    private let disposeBag = DisposeBag()
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init() {
        self.transform()
        self.bindPetProfilesToCellData()
    }
    
    private func transform() {
        self.input
            .bind(onNext: { [weak self] input in
                guard let self else { return }
                
                switch input {
                    
                case .sender(let sender):
                    
                    switch sender {
                    case .pictureRequest:
                        self.output.sender.accept(.pictureRequest)
                        self.output.buttonName.accept("선택 완료")
                        self.output.cellData.accept([
                            RequestDataSource(model: "수사일지 사진 업로드",
                                              items: [
                                                CellList(title: "사진 찍기", image: "camera"),
                                                CellList(title: "사진 보관함", image: "gallery")
                                              ])
                        ])
                    case .pictureRequestForAssistant:
                        self.output.sender.accept(.pictureRequestForAssistant)
                        self.output.buttonName.accept("선택 완료")
                        self.output.cellData.accept([
                            RequestDataSource(model: "프로필 사진 설정",
                                              items: [
                                                CellList(title: "기본 아바타 설정", image: "avatar"),
                                                CellList(title: "사진 찍기", image: "camera"),
                                                CellList(title: "사진 보관함", image: "gallery"),
                                              ])
                        ])
                        
                    case .pictureRequestForPet:
                        self.output.sender.accept(.pictureRequestForPet)
                        self.output.buttonName.accept("선택 완료")
                        self.output.cellData.accept([
                            RequestDataSource(model: "프로필 사진 설정",
                                              items: [
                                                CellList(title: "기본 아바타 설정", image: "avatar"),
                                                CellList(title: "사진 찍기", image: "camera"),
                                                CellList(title: "사진 보관함", image: "gallery"),
                                              ])
                        ])
                        
                    case .sherlDogRequest:
                        self.output.sender.accept(.sherlDogRequest)
                        self.output.buttonName.accept("선택 완료")
                        self.output.cellData.accept([
                            RequestDataSource(model: "어떤 탐정님과 수사를 하실 건가요?",
                                              items: self.fetchSherlDogList())
                        ])
                    case .sherlDogResult:
                        self.output.sender.accept(.sherlDogResult)
                        self.output.buttonName.accept("닫기")
                        self.output.cellData.accept([
                            RequestDataSource(model: "오늘 수사에 함께한 탐정들",
                                              items: self.fetchSelectedDogList())
                        ])
                    }
                    
                case .setButtonTapped(let index):
                    guard let sender = self.output.sender.value else { return }
                    
                    switch sender {
                        
                    case .pictureRequest:
                        switch index.first {
                        case 0: self.output.moveToView.accept(.camera)
                        case 1: self.output.moveToView.accept(.album)
                        default: return
                        }
                        
                    case .pictureRequestForAssistant:
                        switch index.first {
                        case 0: self.output.moveToView.accept(.avatar)
                        case 1: self.output.moveToView.accept(.camera)
                        case 2: self.output.moveToView.accept(.album)
                        default: return
                        }
                        
                    case .pictureRequestForPet:
                        switch index.first {
                        case 0: self.output.moveToView.accept(.avatar)
                        case 1: self.output.moveToView.accept(.camera)
                        case 2: self.output.moveToView.accept(.album)
                        default: return
                        }
                        
                    case .sherlDogRequest:
                        self.output.petIndex.accept(index)
                        
                        // 선택된 강아지들 프로필 저장
                        var selectedProfiles: [PetProfile] = []
                        for idx in index {
                            if idx >= 0 && idx < output.petProfiles.value.count {
                                selectedProfiles.append(output.petProfiles.value[idx])
                            }
                        }
                        self.output.selectedPetProfiles.accept(selectedProfiles)
                        
                    case .sherlDogResult: return
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    // Firestore에서 강아지 프로필 불러오기
    func fetchPetProfiles() {
        let userId = Auth.auth().currentUser?.uid ?? ""
        
        FirestoreManager.shared.fetchDocuments(
            collection: "PetProfile",
            whereField: "userId",
            isEqualTo: userId,
            orderBy: "createdAt",
            type: PetProfile.self
        )
        .subscribe(onSuccess: { [weak self] profiles in
            self?.output.petProfiles.accept(profiles)
        }, onFailure: { error in
        })
        .disposed(by: disposeBag)
    }
    
    // petProfiles가 변경될 때 cellData를 갱신
    private func bindPetProfilesToCellData() {
        // petProfiles
        output.petProfiles
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let sender = self.output.sender.value {
                    switch sender {
                    case .sherlDogRequest:
                        self.output.cellData.accept([
                            RequestDataSource(
                                model: "어떤 탐정님과 수사를 하실 건가요?",
                                items: self.fetchSherlDogList()
                            )
                        ])
                    case .sherlDogResult:
                        self.output.cellData.accept([
                            RequestDataSource(
                                model: "오늘 수사에 함께한 탐정들",
                                items: self.fetchSelectedDogList()
                            )
                        ])
                    default: break
                    }
                }
            })
            .disposed(by: disposeBag)
        
        // selectedPetProfiles
        output.selectedPetProfiles
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let sender = self.output.sender.value, sender == .sherlDogResult {
                    self.output.cellData.accept([
                        RequestDataSource(
                            model: "오늘 수사에 함께한 탐정들",
                            items: self.fetchSelectedDogList()
                        )
                    ])
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchSherlDogList() -> [CellList] {
        return output.petProfiles.value.map { profile in
            CellList(title: profile.name, image: profile.image)
        }
    }
    
    private func fetchSelectedDogList() -> [CellList] {
        let selectedProfiles = output.selectedPetProfiles.value
        
        if selectedProfiles.isEmpty {
            return [CellList(title: "선택된 탐정이 없습니다", image: "placeholder")]
        }
        
        let cellList = selectedProfiles.map { profile in
            return CellList(title: profile.name, image: profile.image)
        }
        
        return cellList
    }
}
