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
        let mapBounds: BehaviorRelay<NMGLatLngBounds>
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
    let mapBounds = BehaviorRelay<NMGLatLngBounds>(value: .init())
    
    // MARK: - Outputs
    
    private let fullSideOfCourse = PublishRelay<NMGLatLngBounds>()
    private let clues = BehaviorRelay<[ClueModel]>(value: [])
    private let sessionState = BehaviorRelay<WalkSession.State>(value: .initial)
    
    // MARK: - Dependencies
    
    private let locationManager: CLLocationManager
    private let walkSession: WalkSession
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        self.walkSession = WalkSession(locationManager: locationManager)
        
        self.input = Input(
            startTracking: startTracking,
            stopTracking: stopTracking,
            mapBounds: mapBounds
        )
        
        self.output = Output(
            fullSideOfCourse: fullSideOfCourse,
            clues: clues,
            sessionState: sessionState
        )
        
        bindInputs()
        bindSession()
        bindClues()
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
        input.mapBounds
            .subscribe(onNext: { [weak self] bounds in
                self?.fetchClues(bounds: bounds)
            })
            .disposed(by: disposeBag)
    }
    // MARK: - Clues
    
    private func fetchClues(bounds: NMGLatLngBounds) {
        guard let userId = AuthSession.currentAppUserId,
                 !userId.isEmpty else {
               self.clues.accept([])
               return
           }
        
        FirestoreManager.shared.fetchQuery(
            FirestoreQuery<ClueModel>(
                collection: .clues,
                type: .clue(before: 365, // 몇일 전까지의 데이터를 불러올 것인지
                            bounds: (
                                s: bounds.southWestLat,
                                w: bounds.southWestLng,
                                n: bounds.northEastLat,
                                e: bounds.northEastLng
                            )
                           )
            )
        )
        .subscribe(
            onSuccess: { [weak self] clues in
                self?.clues.accept(clues)
            },
            onFailure: { error in }
        )
        .disposed(by: disposeBag)
    }
}

