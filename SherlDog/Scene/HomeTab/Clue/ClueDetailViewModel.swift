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
import os.signpost

final class ClueDetailViewModel {
    
    private let disposeBag = DisposeBag()
    
    struct ClueCellData {
        let imageURL: String
        let content: String
    }
    
    // MARK: - Inputs
    enum Input {
        
    }
    
    // MARK: - Outputs
    struct Output {
        let cellData = BehaviorRelay<[ClueDataSource]>(value: [
            ClueDataSource(model: "",
                           items: [ClueCellData(imageURL: "",        
                                                content: "")])
        ])
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
        updateUI(with: clue)
    }
    
    // 새로운 초기화 메서드 추가
    init(coordinate: CLLocationCoordinate2D) {
        // 좌표만으로 새 단서를 만드는 경우
        
    }
    
    // 오늘 남긴 단서 표시
    init(day: Date) {
        fetchCluesData(day: day)
    }
    
    private func updateUI(with clue: ClueModel) {
        data.append(ClueCellData(imageURL: clue.image, content: clue.content))
    }
    
    private func fetchCluesData(day: Date) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        FirestoreManager.shared.fetchDocumentsForDay(collection: "clues",
                                               whereField: "userID",
                                               isEqualTo: userId,
                                               orderBy: "date",
                                                     day: day,
                                               type: ClueModel.self)
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        .subscribe(onSuccess: { [weak self] clues in
            clues.forEach {
                self?.data.append(ClueCellData(imageURL: $0.image, content: $0.content))
            }
        })
        .disposed(by: disposeBag)
    }
}
