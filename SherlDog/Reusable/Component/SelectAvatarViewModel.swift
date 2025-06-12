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

class SelectAvatarViewModel {
    
    enum Input {
        case goNext(Int)
    }
    
    struct Output {
        let cellData = BehaviorRelay(value: [SelectAvatarDataSource]())
        let moveToDetailView = PublishRelay<Void>()
        let selectedAvatar = BehaviorRelay<Int>(value: 0)
    }
    
    typealias SelectAvatarDataSource = SectionModel<String, String>
    
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
            case .goNext(let index):
                self.output.moveToDetailView.accept(())
                self.output.selectedAvatar.accept(index)
            }
        }
        .disposed(by: disposeBag)
    }
    
    private func fetchCellData() {
        self.output.cellData.accept([ // smiley
            SelectAvatarDataSource(model: "탐정님과 함께할 조수를 선택해주세요!", items: [
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
