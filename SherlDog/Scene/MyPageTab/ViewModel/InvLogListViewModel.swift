//
//  InvLogListViewModel.swift
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

// MARK: - InvLogListViewModel
class InvLogListViewModel {
    
    typealias InvLogListDataSource = SectionModel<String, WalkResultToList>
    
    private let disposeBag = DisposeBag()
    private var data = [WalkResultToList]() {
        didSet {
            self.output.cellData.accept([InvLogListDataSource(model: "", items: self.data)])
        }
    }
    var originalData = [(WalkResult, [PetProfile])]()
    
    enum Input {
        case viewWillAppear
        case delete([IndexPath])
        case selectModeConvert
    }
    
    struct Output {
        let cellData = BehaviorRelay<[InvLogListDataSource]>(value: [])
        let isSelectMode = BehaviorRelay<Bool>(value: false)
        let deleteCompleted = PublishRelay<Void>()
    }
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    // MARK: - Initialize
    init() {
        transform()
    }
    
}

// MARK: - Method
extension InvLogListViewModel {
    
    private func transform() {
        self.input
            .bind(onNext: { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .viewWillAppear:
                    self.fetchWalkResultData()
                    
                case .selectModeConvert:
                    self.output.isSelectMode.accept(!self.output.isSelectMode.value)
                    
                case .delete(let index):
                    self.deleteWalkResultData(at: index)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchWalkResultData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        self.data = []
        self.originalData = []
        
        FirestoreManager.shared.fetchQuery(
            FirestoreQuery<WalkResult>(
                collection: .walkResult,
                type: .whereField(field: "userId", value: userId)
                )
        )
            .flatMap { [weak self] result -> Single<[(WalkResult, [PetProfile])]> in
                guard let self else { return .error(FirestoreError.unknown) }
                let petSingles = result.map { result in
                    return self.loadPetProfile(ids: result.petProfileId)
                }
                
                let datas = Single.zip(petSingles)
                    .map { petArray in
                        return zip(result, petArray).map { ($0, $1) }
                    }
                
                return datas
            }
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
            })
            .disposed(by: disposeBag)
    }
    
    private func loadPetProfile(ids: [String]) -> Single<[PetProfile]> {
        let pets = ids.map { id in
            return FirestoreManager.shared.fetchQuery(
                FirestoreQuery<PetProfile>(
                    collection: .petProfile,
                    type: .document(id: id)
                )
            )
            .flatMap { documents -> Single<PetProfile> in
                guard let pet = documents.first else { return .error(FirestoreError.noData) }
                return .just(pet)
            }
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        }
        
        return Single.zip(pets)
    }
    
    private func deleteWalkResultData(at indexPath: [IndexPath]) {
        let cases = indexPath.map { self.data[$0.row].caseNumber }
        let walkingPaths = indexPath.map { self.originalData[$0.row].0.walkingPathImage }
        
        let tasks: [Single<Void>] = indexPath.map { indexPath in
            return FirestoreManager.shared.findDocumentId(collection: .walkResult,
                                                          whereField: "walkingPathImage",
                                                          isEqualTo: self.originalData[indexPath.row].0.walkingPathImage)
            .flatMap { documentId -> Single<Void> in
                guard let id = documentId.first else { return .error(FirestoreError.noData) }
                
                return FirestoreManager.shared.deleteDocument(collection: .walkResult, documentId: id)
                    .andThen(FirebaseImageManager.shared.deleteImageByURL(self.originalData[indexPath.row].0.walkingPathImage))
                    .andThen(.just(()))
            }
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        }
        
        Single.zip(tasks)
            .asCompletable()
            .subscribe(onCompleted: { [weak self] in
                guard let self else { return }
                
                self.data.removeAll { cases.contains($0.caseNumber) }
                self.originalData.removeAll { walkingPaths.contains($0.0.walkingPathImage) }
                
                self.output.deleteCompleted.accept(())
            })
            .disposed(by: disposeBag)
        
    }
}
