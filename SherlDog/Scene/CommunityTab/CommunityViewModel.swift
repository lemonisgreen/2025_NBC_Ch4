//
//  CommunityViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 8/6/25.
//

import RxSwift
import RxRelay
import RxDataSources
import Differentiator

class CommunityViewModel {
    
    enum CommunitySectionType: CaseIterable {
        case invLogBoard
        case detectiveMateBoard
        
        var name: String {
            switch self {
            case .invLogBoard:
                return "수사 게시판"
            case .detectiveMateBoard:
                return "탐정 메이트"
            }
        }
    }
    
    enum Input {
        case segmentedControlChanged(Int)
        case upToRefresh
        case fetchMoreData
    }
    
    struct Output {
        let sectionName = BehaviorRelay<[String]>(value: [])
        let selectedCategory = BehaviorRelay<CommunitySectionType>(value: .invLogBoard)
        let currentCellData = BehaviorRelay<[CommunitySectionType: [CommunityData]]>(value: [:])
    }
    
    typealias CommunityData = SectionModel<String, CommunityModel>
    
    private let disposeBag = DisposeBag()
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init() {
        setup()
        transform()
    }
    
    private func transform() {
        self.input
            .bind(onNext: { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .segmentedControlChanged(let index):
                    let category: CommunitySectionType = {
                        switch index {
                        case 0: return .invLogBoard
                        case 1: return .detectiveMateBoard
                        default: return .invLogBoard
                        }
                    }()
                    
                    self.output.selectedCategory.accept(category)
                    self.setCellData(category: category)
                    
                case .upToRefresh:
                    self.upToRefresh(category: self.output.selectedCategory.value)
                    
                case .fetchMoreData:
                    self.fetchMoreData(category: self.output.selectedCategory.value)
                    
                }
            })
            .disposed(by: disposeBag)
    }
    
    // 초기 커뮤니티 데이터 불러오기
    private func setCellData(category: CommunitySectionType) {
        guard self.output.currentCellData.value[category]?.isEmpty ?? true else { return }
        
        var cache = [CommunityModel]()
        
        // todo: fetch 기능 구현
        cache = MockUpData.communitySample
        if category == .detectiveMateBoard {
            cache.removeLast(2)
        }
        
        let result = [CommunityData(model: "", items: cache)]
        self.output.currentCellData.accept([category: result])
    }
    
    // todo: upToRefresh 기능 구현
    private func upToRefresh(category: CommunitySectionType) {
        guard var cache = self.output.currentCellData.value[category]?[0].items else { return }
        
        cache = MockUpData.communitySample // test
        
        let result = [CommunityData(model: "", items: cache)]
        self.output.currentCellData.accept([category: result])
    }
    
    // todo: 무한스크롤 기능 구현
    private func fetchMoreData(category: CommunitySectionType) {
        guard var cache = self.output.currentCellData.value[category]?[0].items else { return }
        
        MockUpData.communitySample.forEach { // test
            cache.append($0)
        }
        
        let result = [CommunityData(model: "", items: cache)]
        self.output.currentCellData.accept([category: result])
    }
    
    private func setup() {
        var names = [String]()
        
        CommunitySectionType.allCases.forEach {
            names.append($0.name)
        }
        
        self.output.sectionName.accept(names)
        self.output.currentCellData.accept([.invLogBoard: []])
        self.output.currentCellData.accept([.detectiveMateBoard: []])
    }
}
