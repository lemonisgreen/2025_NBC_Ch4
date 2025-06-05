//
//  PictureUploadViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 6/5/25.
//

import RxSwift
import RxRelay
import RxDataSources
import Differentiator

class PictureUploadRequestViewModel {
    
    enum Input {
        case defaultRequest
        case haveIcon
    }
    
    struct Output {
        let title: String
        let image: String
    }
    
    typealias PictureRequestSection = SectionModel<String, PictureUploadRequestViewModel.Output>
    
    private let disposeBag = DisposeBag()
    
    let input = PublishRelay<Input>()
    let output = BehaviorRelay(value: [PictureRequestSection]())
    
    init() {
        self.transform()
    }
    
    private func transform() {
        self.input.bind { [weak self] input in
            guard let self else { return }
            
            switch input {
                
            case .defaultRequest:
                self.output.accept([
                    PictureRequestSection(model: "수사 일지 사진 업로드",
                                          items: [Output(title: "사진 보관함", image: "imageName"),
                                                  Output(title: "사진 찍기", image: "imageName")])
                ])
            case .haveIcon:
                self.output.accept([
                    PictureRequestSection(model: "프로필 사진 선택",
                                          items: [Output(title: "기본 아바타 선택", image: "imageName"),
                                                  Output(title: "사진 보관함", image: "imageName"),
                                                  Output(title: "사진 찍기", image: "imageName"),
                                                 ])
                ])
            }
        }.disposed(by: disposeBag)
    }
    
}
