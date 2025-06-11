//
//  SelectDefaultAvatarViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 6/10/25.
//

import RxSwift
import RxRelay
import RxDataSources
import Differentiator

class SelectDefaultAvatarViewModel {
    
    enum Input {
        case goBack
        case goNext
    }
    
    struct Output {
        let cellData = BehaviorRelay(value: [DataSource]())
        let buttonOutput = PublishRelay<Input>()
    }
    
    typealias DataSource = SectionModel<String, String>
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    private let disposeBag = DisposeBag()
    
    init() {
        transform()
        fetchCellData()
    }
    
    private func transform() {
        self.input.bind { input in
            switch input {
            case .goBack:
                self.output.buttonOutput.accept(.goBack)
            case .goNext:
                self.output.buttonOutput.accept(.goNext)
            }
        }
        .disposed(by: disposeBag)
    }
    
    private func fetchCellData() {
        self.output.cellData.accept([ // smiley
            DataSource(model: "탐정님과 함께할 조수를 선택해주세요!", items: [
                "face.smiling",
                "face.smiling",
                "face.smiling",
                "face.smiling",
                "face.smiling",
                "face.smiling"
            ])
        ])
    }
}
