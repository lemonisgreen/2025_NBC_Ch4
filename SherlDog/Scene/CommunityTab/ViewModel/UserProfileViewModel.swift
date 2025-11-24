//
//  UserProfileViewModel.swift
//  SherlDog
//
//  Created by JIN LEE on 9/22/25.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth

final class UserProfileViewModel {
    let userId: String
    
    struct Input {
        let menuEvent: Observable<PostMenuEvent>
    }
    
    struct Output {
        let humanProfile: BehaviorRelay<HumanProfileModel?>
        let petProfiles: BehaviorRelay<[PetProfile]>
        let menuComplete: Signal<PostMenuEvent>
        
        init(humanProfile: BehaviorRelay<HumanProfileModel?> = .init(value: nil),
             petProfiles: BehaviorRelay<[PetProfile]> = .init(value: []),
             menuComplete: Signal<PostMenuEvent>) {
            self.humanProfile = humanProfile
            self.petProfiles = petProfiles
            self.menuComplete = menuComplete
        }
    }
    
    let output: Output
    private let disposeBag = DisposeBag()
    
    init(userId: String) {
        self.userId = userId
        self.output = Output(menuComplete: .empty())
        fetchHumanProfile()
        fetchPetProfiles()
    }
    
    func transform(_ input: Input) -> Output {
        let menuComplete = menuButtonEvent(input.menuEvent)
        return Output(
            humanProfile: output.humanProfile,
            petProfiles: output.petProfiles,
            menuComplete: menuComplete
        )
    }
    
    private func menuButtonEvent(_ input: Observable<PostMenuEvent>) -> Signal<PostMenuEvent> {
        input
            .flatMapLatest { menu -> Observable<PostMenuEvent> in
                switch menu {
                case .report(let userId):
                    let reportData = BlockModel(collection: FirestoreCollection.humanProfile.rawValue,
                                                 documentId: userId)
                    return FirestoreManager.shared.createDocument(
                        collection: .blockLog,
                        data: reportData,
                        documentId: userId
                    )
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                    .andThen(.just(.report(userId)))
                    .catchAndReturn(.error)
                    
                case .block(let userId):
                    return BlockManager.shared.blockUser(userId)
                        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                        .andThen(.just(.block(userId)))
                        .catchAndReturn(.error)
                    
                default:
                    return .just(.error)
                }
            }
            .asSignal(onErrorJustReturn: .error)
    }
    
    private func fetchHumanProfile() {
        FirestoreManager.shared.fetchQuery(FirestoreQuery<HumanProfileModel>(
            collection: .humanProfile,
            type: .document(id: userId)
        ))
        .subscribe(onSuccess: { [weak self] profiles in
            self?.output.humanProfile.accept(profiles.first)
        }, onFailure: { [weak self] _ in
            self?.output.humanProfile.accept(nil)
        })
        .disposed(by: disposeBag)
    }
    
    private func fetchPetProfiles() {
        FirestoreManager.shared.fetchQuery(FirestoreQuery<PetProfile>(
            collection: .petProfile,
            type: .whereField(field: "userId", value: userId)
        ))
        .subscribe(onSuccess: { [weak self] pets in
            self?.output.petProfiles.accept(pets)
        }, onFailure: { [weak self] _ in
            self?.output.petProfiles.accept([])
        })
        .disposed(by: disposeBag)
    }
    
    func calculatePageIndex(from contentOffset: CGPoint) -> Int {
        let cellWidth: CGFloat = 336
        let cellSpacing: CGFloat = 12
        let totalCellWidth = cellWidth + cellSpacing
        let index = round(contentOffset.x / totalCellWidth)
        return max(0, Int(index))
    }
}
