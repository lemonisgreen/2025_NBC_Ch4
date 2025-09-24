//
//  MyPageViewModel.swift
//  SherlDog
//
//  Created by JIN LEE on 6/26/25.
//

import RxSwift
import RxRelay
import FirebaseAuth

class MyPageViewModel {
    private let disposeBag = DisposeBag()
    
    struct Input {
        let refreshTrigger = PublishSubject<Void>()
        let profileUpdateTrigger = PublishSubject<Void>()
        let humanProfileRefreshTrigger = PublishSubject<Void>()
    }
    
    struct Output {
        let petProfiles = BehaviorRelay<[PetProfile]>(value: [])
        let isLoading = BehaviorRelay<Bool>(value: false)
        let errorMessage = PublishSubject<String>()
        let humanProfile = BehaviorRelay<HumanProfileModel?>(value: nil)
    }
    
    let input = Input()
    let output = Output()
    
    let userId = Auth.auth().currentUser?.uid ?? "anonymous"
    
    // 페이지 계산을 위한 설정값들
    private let cardWidth: CGFloat = 336
    private let spacing: CGFloat = 12
    private let leftInset: CGFloat = 16
    
    init() {
        setupBindings()
        fetchUserPetProfiles()
        fetchHumanProfile()
    }
    
    private func setupBindings() {
        Observable.merge(
            input.refreshTrigger.asObservable(),
            input.profileUpdateTrigger.asObservable()
        )
        .subscribe(onNext: { [weak self] in
            self?.fetchUserPetProfiles()
        })
        .disposed(by: disposeBag)
        
        input.humanProfileRefreshTrigger
            .subscribe(onNext: { [weak self] in
                self?.fetchHumanProfile()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public Methods
    func refresh() {
        input.refreshTrigger.onNext(())
    }
    
    func profileDidUpdate() {
        input.profileUpdateTrigger.onNext(())
    }
    
    func refreshHumanProfile() {
        input.humanProfileRefreshTrigger.onNext(())
    }
    
    func handleNewProfileAdded(with petProfileID: String) {
         addNewProfile(with: petProfileID)
     }
    
    func calculatePageIndex(from contentOffset: CGPoint) -> Int {
        let adjustedOffset = contentOffset.x + leftInset
        let index = Int((adjustedOffset + cardWidth / 2) / (cardWidth + spacing))
        return max(0, index)
    }
    
    // MARK: - Private Methods
    private func fetchUserPetProfiles() {
        output.isLoading.accept(true)
        
        FirestoreManager.shared.fetchQuery(
            FirestoreQuery<PetProfile>(
                collection: .petProfile,
                type: .whereField(field: "userId", value: userId)
            )
        )
        .subscribe(
            onSuccess: { [weak self] profiles in
                self?.output.petProfiles.accept(profiles)
                self?.output.isLoading.accept(false)
            },
            onFailure: { [weak self] error in
                self?.output.errorMessage.onNext("펫 프로필 불러오기 실패: \(error.localizedDescription)")
                self?.output.petProfiles.accept([])
                self?.output.isLoading.accept(false)
            }
        )
        .disposed(by: disposeBag)
    }
    
    private func fetchHumanProfile() {
        FirestoreManager.shared.fetchQuery(
            FirestoreQuery<HumanProfileModel>(
                collection: .humanProfile,
                type: .document(id: userId)
            )
        )
        .subscribe(
            onSuccess: { [weak self] humanProfiles in
                   guard let profile = humanProfiles.first else {
                       return
                   }
                   self?.output.humanProfile.accept(profile)
               },
            onFailure: { [weak self] error in
                self?.output.errorMessage.onNext("HumanProfile 로드 실패: \(error.localizedDescription)")
                let defaultProfile = HumanProfileModel(nickname: "똥봉투조수", image: "", introduce: "")
                self?.output.humanProfile.accept(defaultProfile)
            }
        )
        .disposed(by: disposeBag)
    }
    
    private func addNewProfile(with petProfileID: String) {
        guard !petProfileID.isEmpty else { return }
        
        FirestoreManager.shared.fetchQuery(
            FirestoreQuery<PetProfile>(
                collection: .petProfile,
                type: .document(id: petProfileID)
            )
        )
        .subscribe(onSuccess: { [weak self] newProfile in
            guard let self = self else { return }
            
            var currentProfiles = self.output.petProfiles.value
            currentProfiles.append(contentsOf: newProfile)
            
            DispatchQueue.main.async {
                self.output.petProfiles.accept(currentProfiles)
            }
        }, onFailure: { error in
            print("펫 프로필 불러오기 실패: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.refresh()
            }
        })
        .disposed(by: disposeBag)
    }
    
    // MARK: - Profile Deletion
    func deleteProfile(_ profile: PetProfile) {
        let profileId = profile.petProfileId

        FirestoreManager.shared.deleteDocument(
            collection: .petProfile,
            documentId: profileId
        )
        .subscribe(onCompleted: { [weak self] in
            guard let self = self else { return }
            var currentProfiles = self.output.petProfiles.value
            currentProfiles.removeAll { $0.petProfileId == profileId }
            self.output.petProfiles.accept(currentProfiles)
        }, onError: { [weak self] error in
            self?.output.errorMessage.onNext("펫 프로필 삭제 실패: \(error.localizedDescription)")
        })
        .disposed(by: disposeBag)
    }
}
