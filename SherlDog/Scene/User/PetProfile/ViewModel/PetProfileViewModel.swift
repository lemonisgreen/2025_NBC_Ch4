//
//  PetProfileViewModel.swift
//  SherlDog
//
//  Created by JIN LEE on 8/18/25.
//
import Foundation
import RxSwift
import RxCocoa
import FirebaseAuth
import FirebaseFirestore

final class PetProfileViewModel {
    
    // MARK: - Inputs
    struct Input {
        let loadProfiles = PublishRelay<Void>()
        let addProfile = PublishRelay<String>()
        let deleteProfile = PublishRelay<Int>()
        let nextButton = PublishRelay<Void>()
        let editProfileId = PublishRelay<String>()
    }
    
    // MARK: - Outputs
    struct Output {
        let petProfiles = BehaviorRelay<[PetProfile]>(value: [])
        let isLoading = BehaviorRelay<Bool>(value: false)
        let isNextButtonEnabled = BehaviorRelay<Bool>(value: false)
        let showRegistrationScreen = PublishSubject<Void>()
        let showEditScreen = PublishSubject<PetProfile>()
        let saveResult = PublishSubject<Result<Void, Error>>()
        let profileForEdit = PublishSubject<PetProfile>()
        let errorMessage = PublishSubject<String>()
    }
    
    let input = Input()
    let output = Output()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization and Bindings
    init() {
        bindInputs()
    }
    
    private func bindInputs() {
        
        input.loadProfiles
            .do(onNext: { [weak self] _ in
                self?.output.isLoading.accept(true)
            })
            .flatMapLatest { _ -> Observable<[PetProfile]> in
                guard let uid = Auth.auth().currentUser?.uid else {
                    return .just([])
                }
                return FirestoreManager.shared.fetchUserPetProfiles(userId: uid)
                    .asObservable()
                    .catch { error in
                        self.output.errorMessage.onNext("프로필 불러오기 실패: \(error.localizedDescription)")
                        return .just([])
                    }
            }
            .subscribe(onNext: { [weak self] profiles in
                self?.output.petProfiles.accept(profiles)
                self?.output.isLoading.accept(false)
                self?.output.isNextButtonEnabled.accept(!profiles.isEmpty)
            })
            .disposed(by: disposeBag)
        
        input.addProfile
            .flatMapLatest { petProfileID -> Observable<PetProfile> in
                FirestoreManager.shared.fetchPetProfileById(petProfileId: petProfileID)
                    .asObservable()
                    .catch { error in
                        self.output.errorMessage.onNext("프로필 추가 실패: \(error.localizedDescription)")
                        return .empty()
                    }
            }
            .withLatestFrom(output.petProfiles) { newProfile, profiles in
                profiles + [newProfile]
            }
            .subscribe(onNext: { [weak self] newProfiles in
                self?.output.petProfiles.accept(newProfiles)
                self?.output.isNextButtonEnabled.accept(!newProfiles.isEmpty)
            })
            .disposed(by: disposeBag)
        
        input.deleteProfile
            .withLatestFrom(output.petProfiles) { (index, profiles) in
                return (index, profiles)
            }
            .flatMapLatest { [weak self] (index, profiles) -> Observable<[PetProfile]> in
                guard let self = self,
                      index < profiles.count else {
                    return Observable.empty()
                }
                let petProfileId = profiles[index].petProfileId
                
                return FirestoreManager.shared.deleteDocument(collection: "PetProfile", documentId: petProfileId)
                    .andThen(Observable.just(profiles.enumerated()
                        .filter { $0.offset != index }
                        .map { $0.element }))
                    .catch { error in
                        self.output.errorMessage.onNext("삭제 실패: \(error.localizedDescription)")
                        return Observable.empty()
                    }
            }
            .bind(to: output.petProfiles)
            .disposed(by: disposeBag)
        
        input.nextButton
            .withLatestFrom(output.isNextButtonEnabled)
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.output.showRegistrationScreen.onNext(())
            })
            .disposed(by: disposeBag)
        
        input.editProfileId
            .flatMapLatest { id in
                FirestoreManager.shared.fetchDocument(collection: "PetProfile", documentId: id, type: PetProfile.self)
                    .asObservable()
                    .catch { [weak self] error in
                        self?.output.errorMessage.onNext("편집 프로필 로딩 실패: \(error.localizedDescription)")
                        return Observable.empty()
                    }
            }
            .bind(to: output.profileForEdit)
            .disposed(by: disposeBag)
    }
    
    func editProfile(_ profile: PetProfile) {
        output.showEditScreen.onNext(profile)
    }
}
