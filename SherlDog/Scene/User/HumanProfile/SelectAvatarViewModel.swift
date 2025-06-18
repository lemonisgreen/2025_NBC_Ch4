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
        case completeSelect
    }
    
    struct Output {
        let cellData = BehaviorRelay(value: [SelectAvatarDataSource]())
        let moveToDetailView = PublishRelay<Void>()
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
        self.input.bind { input in
            switch input {
            case .goNext(let index):
                self.output.moveToDetailView.accept(())
                self.output.selectedAvatar.accept(self.data[index])
            case .completeSelect:
                guard let imageName = self.output.selectedAvatar.value?.icon else { return }
                self.output.completeSelect.accept(imageName)
            }
        }
        .disposed(by: disposeBag)
    }
    
    private func fetchCellData() {
        self.output.cellData.accept([
            SelectAvatarDataSource(model: "탐정님과 함께할 조수를 선택해주세요!",
                                   items: self.data.map { $0.icon })
        ])
    }
}
