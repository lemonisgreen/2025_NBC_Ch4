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
        var clue: ClueModel
        let profile: HumanProfileModel?
        var imageURL: String { clue.image }
        var content: String { clue.content }
        var header: PostHeaderModel {
            PostHeaderModel(profileImage: profile?.image ?? "",
                            name: profile?.nickname ?? SDLiteral.CommunityView.unknownUser,
                            petProfile: [], postDate: clue.date)
        }
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
            self.clueCount.accept(data.count)
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
    
    func applyMenuResult(_ event: PostMenuEvent) {
        switch event {
        case .delete(let id), .report(let id):
            data.removeAll { $0.clue.documentId == id }
        case .block(let userId):
            data.removeAll { $0.clue.userID == userId }
        case .fix, .error:
            break
        }
    }

    func updateClue(_ clue: ClueModel) {
        guard let id = clue.documentId,
              let index = data.firstIndex(where: { $0.clue.documentId == id }) else { return }
        data[index].clue = clue
    }

    private func updateUI(with clue: ClueModel) {
        updateCluster(with: [clue])
    }

    private func updateCluster(with clues: [ClueModel]) {
        guard !clues.isEmpty else {
            data = []
            output.isLoading.accept(false)
            return
        }
        
        let clues = clues.sorted {
            $0.date.dateValue() > $1.date.dateValue()
        }
        
        let profiles = Set(clues.map(\.userID)).map { userId in
            FirestoreManager.shared.fetchQuery(FirestoreQuery<HumanProfileModel>(
                collection: .humanProfile, type: .document(id: userId)
            ))
            .map { (userId, $0.first) }
            .catchAndReturn((userId, nil))
        }
        Single.zip(profiles)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] profiles in
                let byId = Dictionary(uniqueKeysWithValues: profiles)
                self?.data = clues.map { ClueCellData(clue: $0, profile: byId[$0.userID] ?? nil) }
                self?.output.isLoading.accept(false)
            }, onFailure: { [weak self] error in
                self?.output.isLoading.accept(false)
                self?.output.errorMessage.accept(error.localizedDescription)
            })
            .disposed(by: disposeBag)
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
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] clues in
                guard let self else { return }
                
                self.updateCluster(with: clues)
            },
            onFailure: { [weak self] error in
                self?.output.isLoading.accept(false)
                self?.output.errorMessage.accept(error.localizedDescription)
            }
        )
        .disposed(by: disposeBag)
    }
}
