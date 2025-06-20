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
    }
    
    typealias RequestDataSource = SectionModel<String, CellList>
    
    private let disposeBag = DisposeBag()
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init() {
        self.transform()
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
                                           items: self.fetchSherlDogList())
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
                        
                    case .sherlDogRequest:  // 수사할 탐정 선택
                        self.output.petIndex.accept(index)
                    case .sherlDogResult: return    // .sherlDogResult is read only
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchSherlDogList() -> [CellList] {
        return [
            CellList(title: "멍탐정 1", image: "largeDog"),
            CellList(title: "멍탐정 2", image: "mediumDog"),
            CellList(title: "멍탐정 3", image: "smallDog"),
        ]
    }
    
}
