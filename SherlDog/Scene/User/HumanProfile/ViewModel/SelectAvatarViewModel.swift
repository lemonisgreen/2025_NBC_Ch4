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
        let selectedAvatar = BehaviorRelay<AvatarModel?>(value: nil)
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
        
        if let firstAvatar = data.first {
            output.selectedAvatar.accept(firstAvatar)
            let icon = firstAvatar.icon
            let selectedIcon = "selected" + icon.prefix(1).capitalized + icon.dropFirst()
            output.icon.accept(selectedIcon)
        }
    }
    
    private func transform() {
        self.input
            .bind { input in
                switch input {
                case .avatarSelect(let index):
                    self.output.selectedAvatar.accept(self.data[index])
                    let icon = self.data[index].icon
                    let selectedIcon = "selected" + icon.prefix(1).capitalized + icon.dropFirst()
                    self.output.icon.accept(selectedIcon)
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
