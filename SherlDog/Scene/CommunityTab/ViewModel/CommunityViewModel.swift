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

final class CommunityViewModel {
    
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
        let currentCellData = BehaviorRelay<[CommunitySectionType: [CommunitySection]]>(value: [:])
    }
    
    typealias CommunitySection = SectionModel<CommunityModel, String>

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
                    self.pullToRefresh(category: self.output.selectedCategory.value)
                    
                case .fetchMoreData:
                    self.fetchMoreData(category: self.output.selectedCategory.value)
                    
                }
            })
            .disposed(by: disposeBag)
    }
    
    // 초기 커뮤니티 데이터 불러오기
    private func setCellData(category: CommunitySectionType) {
        // 이미 로드돼 있으면 스킵
        if let cached = output.currentCellData.value[category], cached.isEmpty == false { return }
        
        var collection: String {
            switch category {
            case .invLogBoard: return "InvLogBoard"
            case .detectiveMateBoard: return "DetectiveMate"
            }
        }
        
        FirestoreManager.shared.fetchCollection(collection: collection,
                                                sortField: "postDate",
                                                descending: true,
                                                type: CommunityModel.self)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onSuccess: { [weak self] data in
                guard let self else { return }
                
                let sections = makeSections(from: data)
                updateCellData(for: category, with: sections)
            })
            .disposed(by: disposeBag)
    }
    
    // pullToRefresh
    private func pullToRefresh(category: CommunitySectionType) {
        var posts = MockUpData.communitySample // FIXME: 최신 데이터 fetch
        if category == .detectiveMateBoard, posts.count >= 2 {
            posts.removeLast(2)
        }
        
        let sections = makeSections(from: posts)
        updateCellData(for: category, with: sections)
    }
    
    // 무한스크롤
    private func fetchMoreData(category: CommunitySectionType) {
        // 기존 섹션 -> 기존 포스트 복원
        let existingSections = output.currentCellData.value[category] ?? []
        let existingPosts: [CommunityModel] = existingSections.map { $0.model }
        
        // 더 불러온 포스트(예시로 샘플 append)
        var more = MockUpData.communitySample // FIXME: 페이지네이션 fetch
        if category == .detectiveMateBoard, more.count >= 2 {
            more.removeLast(2)
        }
        
        let combinedPosts = existingPosts + more
        let sections = makeSections(from: combinedPosts)
        updateCellData(for: category, with: sections)
    }
    
    private func setup() {
        // 세그 제목
        output.sectionName.accept(CommunitySectionType.allCases.map { $0.name })
        
        // 카테고리 키만 먼저 만들어 둠(빈 섹션)
        var initDict: [CommunitySectionType: [CommunitySection]] = [:]
        CommunitySectionType.allCases.forEach { initDict[$0] = [] }
        output.currentCellData.accept(initDict)
        
        // 초기 카테고리 로드
        setCellData(category: .invLogBoard)
    }
}

// MARK: - Data mapping helpers
extension CommunityViewModel {
    /// 딕셔너리 업데이트 시 기존 카테고리 데이터 보존
    private func updateCellData(for category: CommunitySectionType, with sections: [CommunitySection]) {
        var dict = output.currentCellData.value
        dict[category] = sections
        output.currentCellData.accept(dict)
    }
    
    /// [CommunityModel] -> [CommunitySection] 로 변환
    private func makeSections(from posts: [CommunityModel]) -> [CommunitySection] {
        return posts.map { post in
            CommunitySection(model: post, items: post.contentImage) // 이미지 URL 배열을 아이템으로
        }
    }
}
