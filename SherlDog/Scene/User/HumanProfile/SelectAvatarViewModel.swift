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
        case avatarSelect(Int)
        case goBack
        case completeSelect
    }
    
    struct Output {
        let cellData = BehaviorRelay(value: [SelectAvatarDataSource]())
        let moveToBack = PublishRelay<Void>()
        let selectedAvatar = PublishRelay<AvatarModel>()
        let icon = BehaviorRelay(value: "")
        let completeSelect = PublishRelay<Void>()
    }
    
    typealias SelectAvatarDataSource = SectionModel<String, String>
    private let data = AvatarModel.avatarData
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    private let disposeBag = DisposeBag()
    
    init() {
        transform()
        fetchCellData()
    }
    
    private func transform() {
        self.input
            .bind { input in
                switch input {
                case .avatarSelect(let index):
                    self.output.selectedAvatar.accept(self.data[index])
                    self.output.icon.accept(self.data[index].icon)
                case .goBack:
                    self.output.moveToBack.accept(())
                case .completeSelect:
                    self.output.completeSelect.accept(())
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func fetchCellData() {
        self.output.cellData.accept([
            SelectAvatarDataSource(model: "",
                                   items: self.data.map { $0.icon })
        ])
    }
}
