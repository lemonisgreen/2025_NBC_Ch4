//
//  ClueDetailViewModel.swift
//  SherlDog
//
//  Created by 김재우 on 6/19/25.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import Differentiator
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import UIKit

final class ClueDetailViewModel {
    
    private let disposeBag = DisposeBag()
    let clueCount = BehaviorRelay<Int>(value: 0)
    
    struct ClueCellData {
        let imageURL: String
        let content: String
    }
    
    // MARK: - Inputs
    enum Input {
        
    }
    
    // MARK: - Outputs
    struct Output {
        let cellData = BehaviorRelay<[ClueDataSource]>(value: [])
        let isLoading = BehaviorRelay<Bool>(value: false)
        let errorMessage = PublishRelay<String>()
    }
    
    typealias ClueDataSource = SectionModel<String, ClueCellData>
    private var data = [ClueCellData]() {
        didSet {
            self.output.cellData.accept([ClueDataSource(model: "", items: self.data)])
        }
    }
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init(clue: ClueModel) {
        self.output.isLoading.accept(true)
        updateUI(with: clue)
    }
    
    init(clues: [ClueModel]) {
        self.output.isLoading.accept(true)
        self.updateCluster(with: clues)
    }
    
    // 새로운 초기화 메서드 추가
    init(coordinate: CLLocationCoordinate2D) {
        // 좌표만으로 새 단서를 만드는 경우
        
    }
    
    // 오늘 남긴 단서 표시
    init(day: Date) {
        self.output.isLoading.accept(true)
        fetchCluesData(day: day)
    }
    
    private func updateUI(with clue: ClueModel) {
        data.append(ClueCellData(imageURL: clue.image, content: clue.content))
        self.output.isLoading.accept(false)
    }
    
    private func updateCluster(with clues: [ClueModel]) {
        self.data = clues.map {
            ClueCellData(imageURL: $0.image, content: $0.content)
        }
        self.clueCount.accept(clues.count)
        self.output.isLoading.accept(false)
    }
    
    private func fetchCluesData(day: Date) {
        let userId = AuthSession.currentAppUserId
        
        FirestoreManager.shared.fetchQuery(
            FirestoreQuery<ClueModel>(
                collection: .clues,
                type: .whereField(field: "userID", value: userId)
            )
        )
        .map { clues in
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: day)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!

            return clues.filter {
                let clueDate = $0.date.dateValue()
                return clueDate >= start && clueDate < end
            }
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        .subscribe(
            onSuccess: { [weak self] clues in
                guard let self else { return }
                
                self.data = clues.map {
                    ClueCellData(
                        imageURL: $0.image,
                        content: $0.content
                    )
                }
                self.clueCount.accept(clues.count)
                self.output.isLoading.accept(false)
            },
            onFailure: { [weak self] error in
                self?.output.isLoading.accept(false)
                self?.output.errorMessage.accept(error.localizedDescription)
            }
        )
        .disposed(by: disposeBag)
    }
}
