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
    }
    
    struct Output {
        let petProfiles = BehaviorRelay<[PetProfile]>(value: [])
        let isLoading = BehaviorRelay<Bool>(value: false)
        let errorMessage = PublishSubject<String>()
    }
    
    let input = Input()
    let output = Output()
    
    // 페이지 계산을 위한 설정값들
    private let cardWidth: CGFloat = 336
    private let spacing: CGFloat = 12
    private let leftInset: CGFloat = 16
    
    init() {
        setupBindings()
        fetchUserPetProfiles() // 초기 로드
    }
    
    private func setupBindings() {
        // 새로고침 트리거
        Observable.merge(
            input.refreshTrigger.asObservable(),
            input.profileUpdateTrigger.asObservable()
        )
        .subscribe(onNext: { [weak self] in
            self?.fetchUserPetProfiles()
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
    
    func calculatePageIndex(from contentOffset: CGPoint) -> Int {
        let adjustedOffset = contentOffset.x + leftInset
        let index = Int((adjustedOffset + cardWidth / 2) / (cardWidth + spacing))
        return max(0, index)
    }
    
    // MARK: - Private Methods
    private func fetchUserPetProfiles() {
        let userId = Auth.auth().currentUser?.uid ?? "anonymous"
        output.isLoading.accept(true)
        
        FirestoreManager.shared.fetchDocuments(
            collection: "PetProfile",
            whereField: "userId",
            isEqualTo: userId,
            type: PetProfile.self
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
}
