//
//  MainViewModel.swift
//  SherlDog
//
//  Created by 김재우 on 6/13/25.
//

import RxSwift
import RxCocoa
import CoreLocation
import NMapsMap
import FirebaseAuth

final class MainViewModel {
    
    // MARK: - Input / Output
    struct Input {
        let startTracking: PublishRelay<Void>
        let stopTracking: PublishRelay<Void>
        let reloadClues: PublishRelay<Void>
    }
    
    struct Output {
        let fullSideOfCourse: PublishRelay<NMGLatLngBounds>
        let clues: BehaviorRelay<[ClueModel]>
        let sessionState: BehaviorRelay<WalkSession.State>
    }
    
    let input: Input
    let output: Output
    
    // MARK: - Inputs
    
    let startTracking = PublishRelay<Void>()
    let stopTracking = PublishRelay<Void>()
    let reloadClues = PublishRelay<Void>()
    
    // MARK: - Outputs
    
    private let fullSideOfCourse = PublishRelay<NMGLatLngBounds>()
    private let clues = BehaviorRelay<[ClueModel]>(value: [])
    private let sessionState = BehaviorRelay<WalkSession.State>(value: .initial)
    
    // MARK: - Dependencies
    
    private let walkSession: WalkSession
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    
    init(locationManager: CLLocationManager) {
        self.walkSession = WalkSession(locationManager: locationManager)
        
        self.input = Input(
            startTracking: startTracking,
            stopTracking: stopTracking,
            reloadClues: reloadClues
        )
        
        self.output = Output(
            fullSideOfCourse: fullSideOfCourse,
            clues: clues,
            sessionState: sessionState
        )
        
        bindInputs()
        bindSession()
    }
    
    // MARK: - Bind
    
    private func bindInputs() {
        input.startTracking
            .subscribe(onNext: { [weak self] in
                self?.walkSession.start()
            })
            .disposed(by: disposeBag)
        
        input.stopTracking
            .subscribe(onNext: { [weak self] in
                self?.walkSession.stop()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSession() {
        walkSession.state
            .bind(to: sessionState)
            .disposed(by: disposeBag)
        
        walkSession.fullSideOfCourse
            .bind(to: fullSideOfCourse)
            .disposed(by: disposeBag)
    }
    
    private func bindClues() {
        input.reloadClues
            .subscribe(onNext: { [weak self] in
                self?.fetchClues()
            })
            .disposed(by: disposeBag)
    }
    // MARK: - Clues
    
    private func fetchClues() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.clues.accept([])
            return
        }
        
        FirestoreManager.shared.fetchQuery(
            FirestoreQuery<ClueModel>(
                collection: .clues,
                type: .whereField(field: "userId", value: userId)
            )
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] myClues in
                self?.clues.accept(myClues)
            },
            onFailure: { error in
                print("단서 불러오기 실패: \(error.localizedDescription)")
            }
        )
        .disposed(by: disposeBag)
    }
}
