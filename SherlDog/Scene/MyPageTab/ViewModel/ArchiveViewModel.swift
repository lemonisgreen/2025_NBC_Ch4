//
//  ArchiveViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 6/25/25.
//

import UIKit
import RxSwift
import RxRelay
import RxDataSources
import Differentiator
import FirebaseAuth
import FirebaseFirestore

enum ArchiveType {
    case invLog
    case clue
    
    var title: String {
        switch self {
        case .invLog:
            SDLiteral.ArchiveView.InvLog.title
        case .clue:
            SDLiteral.ArchiveView.Clue.title
        }
    }
    var onBoardingKey: String {
        switch self {
        case .invLog:
            SDLiteral.ArchiveView.InvLog.onboardingUserDefaults
        case .clue:
            SDLiteral.ArchiveView.Clue.onboardingUserDefaults
        }
    }
}

// MARK: - ArchiveViewModel
class ArchiveViewModel {
    
    enum CellData {
        case invLog(WalkResultToList)
        case clue(ClueToList)
    }

    typealias ArchiveSection = SectionModel<String, CellData>
    
    let type: ArchiveType
    private let disposeBag = DisposeBag()
    private let clueFetch = SerialDisposable()
    private var data = [WalkResultToList]() {
        didSet {
            let items = self.data.map(CellData.invLog)
            self.output.cellData.accept([ArchiveSection(model: "", items: items)])
        }
    }
    var originalData = [(WalkResult, [PetProfile])]()
    
    enum Input {
        case viewWillAppear
        case deleteInvLogs([IndexPath])
        case deleteClues([ClueModel])
        case selectModeConvert
    }
    
    struct Output {
        let cellData = BehaviorRelay<[ArchiveSection]>(value: [])
        let needOnboarding = PublishRelay<Bool>()
        let isSelectMode = BehaviorRelay<Bool>(value: false)
        let deleteCompleted = PublishRelay<Void>()
        let deleteFailed = PublishRelay<String>()
        let isDeleting = BehaviorRelay<Bool>(value: false)
    }
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    // MARK: - Initialize
    init(type: ArchiveType) {
        self.type = type
        clueFetch.disposed(by: disposeBag)
        transform()
    }
    
}

// MARK: - Method
extension ArchiveViewModel {
    
    private func transform() {
        self.input
            .bind(onNext: { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .viewWillAppear:
                    guard !self.output.isDeleting.value else { return }
                    switch self.type {
                    case .invLog: self.fetchWalkResultData()
                    case .clue: self.fetchClueData()
                    }
                    
                case .selectModeConvert:
                    guard !self.output.isDeleting.value else { return }
                    self.output.isSelectMode.accept(!self.output.isSelectMode.value)
                    
                case .deleteInvLogs(let index):
                    guard self.type == .invLog else { return }
                    self.deleteWalkResultData(at: index)

                case .deleteClues(let clues):
                    guard self.type == .clue else { return }
                    self.deleteClues(clues)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func needOnboarding() -> Bool {
        let hasShown = UserDefaults.standard.bool(forKey: self.type.onBoardingKey)
        
        if !hasShown {
            UserDefaults.standard.set(true, forKey: self.type.onBoardingKey)
            return true
        } else {
            return false
        }
    }
    
    private func fetchClueData() {
        guard let userId = AuthSession.currentAppUserId else { return }

        clueFetch.disposable = FirestoreManager.shared.fetchQuery(
            FirestoreQuery<ClueModel>(
                collection: .clues,
                type: .whereField(field: "userID", value: userId)
            )
        )
        .flatMap { data -> Single<[ClueToList]> in
            guard !data.isEmpty else { return .just([]) }
            return FirestoreManager.shared.fetchQuery(
                FirestoreQuery<PetProfile>(
                    collection: .petProfile,
                    type: .whereField(field: "userId", value: userId)
                )
            )
            .catchAndReturn([])
            .map { profiles in
                let sortedClue = data.sorted(by: { $0.date.dateValue() > $1.date.dateValue() } )
                return sortedClue.enumerated().map { index, clue in
                    let caseNumber = sortedClue.count - index
                    
                    return ClueToList(from: clue, caseNumber: caseNumber, profile: profiles)
                }
            }
        }
        .observe(on: MainScheduler.instance)
        .subscribe(onSuccess: { [weak self] rows in
            guard let self else { return }
            let items = rows.map(CellData.clue)
            self.output.cellData.accept([ArchiveSection(model: "", items: items)])
            
            if !items.isEmpty, self.needOnboarding() {
                self.output.needOnboarding.accept(true)
            }
        }, onFailure: { error in
            print("Failed to fetch clue archive: \(error.localizedDescription)")
        })
    }

    private func deleteClues(_ clues: [ClueModel]) {
        guard type == .clue, output.isSelectMode.value, !output.isDeleting.value,
              !clues.isEmpty, let userId = AuthSession.currentAppUserId else { return }

        let ids = Set(clues.compactMap { clue -> String? in
            guard clue.userID == userId, let id = clue.documentId, !id.isEmpty else { return nil }
            return id
        })
        guard ids.count == clues.count else {
            output.deleteFailed.accept(SDLiteral.ArchiveView.Clue.deleteFailed)
            return
        }

        clueFetch.disposable = Disposables.create()
        output.isDeleting.accept(true)

        let requests = ids.map { id in
            FirestoreManager.shared.deleteDocument(collection: .clues, documentId: id)
                .andThen(Single<String?>.just(id))
                .catchAndReturn(nil)
        }
        Single.zip(requests)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] results in
                guard let self else { return }
                let deletedIds = Set(results.compactMap { $0 })
                let remaining = self.output.cellData.value.flatMap(\.items).filter { item in
                    guard case .clue(let row) = item, let id = row.clue.documentId else { return true }
                    return !deletedIds.contains(id)
                }
                if !deletedIds.isEmpty {
                    self.output.cellData.accept([ArchiveSection(model: "", items: remaining)])
                }
                self.output.isDeleting.accept(false)
                if deletedIds.count == ids.count {
                    self.output.deleteCompleted.accept(())
                } else {
                    self.output.deleteFailed.accept(SDLiteral.ArchiveView.Clue.deleteFailed)
                }
            })
            .disposed(by: disposeBag)
    }

    private func fetchWalkResultData() {
        guard let userId = AuthSession.currentAppUserId else { return }
        self.data = []
        self.originalData = []
        
        FirestoreManager.shared.fetchQuery(
            FirestoreQuery<WalkResult>(
                collection: .walkResult,
                type: .whereField(field: "userId", value: userId)
                )
        )
            .flatMap { [weak self] results -> Single<[(WalkResult, [PetProfile])]> in
                guard let self else { return .error(FirestoreError.unknown) }
                let ids = Set(results.flatMap(\.petProfileId))
                return self.loadPetProfiles(ids: ids)
                    .map { profiles in
                        results.map { result in
                            (result, result.petProfileId.compactMap { profiles[$0] })
                        }
                    }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] result in
                guard let self else { return }
                
                // 클라이언트에서 정렬
                let sortedResult = result.sorted {
                    $0.0.createdAt.dateValue() > $1.0.createdAt.dateValue()
                }
                
                self.originalData = sortedResult
                self.data = sortedResult.enumerated().map { index, result in
                    let caseNumber = sortedResult.count - index  // 최신이 큰 번호
                    return WalkResultToList(from: result.0, caseNumber: caseNumber, profile: result.1)
                }
                
                if !self.data.isEmpty, self.needOnboarding() {
                    self.output.needOnboarding.accept(true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func loadPetProfiles(ids: Set<String>) -> Single<[String: PetProfile]> {
        guard !ids.isEmpty else { return .just([:]) }

        let requests = ids.map { id in
            FirestoreManager.shared.fetchQuery(
                FirestoreQuery<PetProfile>(collection: .petProfile, type: .document(id: id))
            )
            .catchAndReturn([])
            .map { profiles in profiles.first.map { (id, $0) } }
        }

        return Single.zip(requests)
            .map { Dictionary(uniqueKeysWithValues: $0.compactMap { $0 }) }
    }

    private func deleteWalkResultData(at indexPaths: [IndexPath]) {
        guard output.isSelectMode.value, !output.isDeleting.value, !indexPaths.isEmpty,
              indexPaths.allSatisfy({ data.indices.contains($0.row) && originalData.indices.contains($0.row) })
        else { return }

        let targets = indexPaths.map { indexPath in
            (row: indexPath.row, path: originalData[indexPath.row].0.walkingPathImage)
        }
        output.isDeleting.accept(true)

        let tasks = targets.map { target -> Single<(documentDeleted: Bool, imageDeleted: Bool)> in
            FirestoreManager.shared.findDocumentId(
                collection: .walkResult,
                whereField: "walkingPathImage",
                isEqualTo: target.path
            )
            .flatMap { documentIds -> Single<(documentDeleted: Bool, imageDeleted: Bool)> in
                guard let id = documentIds.first else { return .just((false, false)) }

                return FirestoreManager.shared.deleteDocument(collection: .walkResult, documentId: id)
                    .andThen(
                        FirebaseImageManager.shared.deleteImageByURL(target.path)
                            .andThen(Single.just((true, true)))
                            .catchAndReturn((true, false))
                    )
            }
            .catchAndReturn((false, false))
        }

        Single.zip(tasks)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] results in
                guard let self else { return }

                let deletedRows = Set(zip(targets, results).compactMap { target, result in
                    result.documentDeleted ? target.row : nil
                })
                if !deletedRows.isEmpty {
                    self.originalData = self.originalData.enumerated().compactMap { index, item in
                        deletedRows.contains(index) ? nil : item
                    }
                    self.data = self.data.enumerated().compactMap { index, item in
                        deletedRows.contains(index) ? nil : item
                    }
                }

                self.output.isDeleting.accept(false)
                if results.allSatisfy({ $0.imageDeleted }) {
                    self.output.deleteCompleted.accept(())
                } else {
                    self.output.deleteFailed.accept(SDLiteral.ArchiveView.InvLog.deleteFailed)
                }
            })
            .disposed(by: disposeBag)
    }
}
