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
        let completeSelect = PublishRelay<String>()
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
                case .goBack:
                    self.output.moveToBack.accept(())
                case .completeSelect:
                    guard let imageName = self.output.selectedAvatar.value?.icon else { return }
                    self.output.completeSelect.accept(imageName)
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
