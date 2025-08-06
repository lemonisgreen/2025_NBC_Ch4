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
    }
    
    struct Output {
        let sectionName = BehaviorRelay<[String]>(value: [])
        let currentCellData = BehaviorRelay<[CommunityData]>(value: [])
    }
    
    typealias CommunityData = SectionModel<String, CommunityModel>
    private var cellDataCache = [CommunitySectionType: [CommunityData]]()
    
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
                    let section: CommunitySectionType = {
                        switch index {
                        case 0: return .invLogBoard
                        case 1: return .detectiveMateBoard
                        default: return .invLogBoard
                        }
                    }()
                    
                    self.setCellData(section: section)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setCellData(section: CommunitySectionType) {
        guard let cache = self.cellDataCache[section], cache.count != 0 else {
            fetchData(section: section)
            return
        }
        
        self.output.currentCellData.accept(cache)
    }
    
    // todo: upToRefresh 기능 구현
    private func upToRefresh(section: CommunitySectionType) {
        var cache = [CommunityData]()
        
        cache = [CommunityData(model: "",
                               items: MockUpData.communitySample)]
        
        self.cellDataCache[section] = cache
        self.output.currentCellData.accept(cache)
    }
    
    // todo: 무한스크롤 기능 구현
    private func fetchMoreData(section: CommunitySectionType) {
        var cache = self.cellDataCache[section] ?? []
        
        cache.append(contentsOf: [CommunityData(model: "",
                                                items: MockUpData.communitySample)])
        
        self.cellDataCache[section] = cache
    }
    
    private func setup() {
        var names = [String]()
        
        CommunitySectionType.allCases.forEach {
            names.append($0.name)
        }
        
        self.output.sectionName.accept(names)
    }
    
    private func fetchData(section: CommunitySectionType) {
        var cache = [CommunityData(model: "",
                                   items: MockUpData.communitySample)]
        
        // todo: 데이터 불러오기 로직 구현
        if section == .detectiveMateBoard {
            cache[0].items.removeLast(2)
        }
        
        self.cellDataCache[section] = cache
        self.output.currentCellData.accept(cache)
    }
}
