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
    
    struct Input {
        let startTracking: PublishRelay<Void>
        let stopTracking: PublishRelay<Void>
        let reloadClues: PublishRelay<Void>
    }
    
    struct Output {
        let fullSideOfCourse: PublishRelay<NMGLatLngBounds>
        let isTracking: BehaviorRelay<Bool>
        let coordinates: BehaviorRelay<[CLLocationCoordinate2D]>
        let steps: BehaviorRelay<Int>
        let distanceMeters: BehaviorRelay<Double>
        let elapsedSeconds: BehaviorRelay<Int>
        let clues: BehaviorRelay<[ClueModel]>
    }
    
    let input: Input
    let output: Output
    
    // input relays
    let startTracking = PublishRelay<Void>()
    let stopTracking = PublishRelay<Void>()
    let reloadClues = PublishRelay<Void>()
    
    // output relays
    private let fullSideOfCourse = PublishRelay<NMGLatLngBounds>()
    private let isTracking = BehaviorRelay<Bool>(value: false)
    private let coordinates = BehaviorRelay<[CLLocationCoordinate2D]>(value: [])
    
    private let steps = BehaviorRelay<Int>(value: 0)
    private let distanceMeters = BehaviorRelay<Double>(value: 0)
    private let elapsedSeconds = BehaviorRelay<Int>(value: 0)
    
    private let clues = BehaviorRelay<[ClueModel]>(value: [])
    
    private let walkSession: WalkSession
    private let disposeBag = DisposeBag()
    
    init(locationManager: CLLocationManager) {
            self.walkSession = WalkSession(locationManager: locationManager)

            self.input = Input(
                startTracking: startTracking,
                stopTracking: stopTracking,
                reloadClues: reloadClues
            )

            self.output = Output(
                fullSideOfCourse: fullSideOfCourse,
                isTracking: isTracking,
                coordinates: coordinates,
                steps: steps,
                distanceMeters: distanceMeters,
                elapsedSeconds: elapsedSeconds,
                clues: clues
            )

            bindInputs()
            bindSessionOutputs()
            // bindClues()  // <- 3번에서 여기 붙일 거야
        }
    
    private func bindInputs() {
        input.startTracking
            .subscribe(onNext: { [weak self] in
                self?.output.isTracking.accept(true)
            })
            .disposed(by: disposeBag)
        
        input.stopTracking
            .subscribe(onNext: { [weak self] in
                self?.walkSession.stop()
            })
            .disposed(by: disposeBag)
        
        input.reloadClues
            .subscribe(onNext: { [weak self] in
                self?.fetchClues()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSessionOutputs() {
        walkSession.state
            .subscribe(onNext: { [weak self] state in
                guard let self else { return }
                self.isTracking.accept(state.isActive)
                self.coordinates.accept(state.coordinates)
                self.steps.accept(state.steps)
                self.distanceMeters.accept(state.distanceMeters)
                self.elapsedSeconds.accept(state.elapsedSeconds)
            })
            .disposed(by: disposeBag)
        
        walkSession.fullSideOfCourse
            .bind(to: fullSideOfCourse)
            .disposed(by: disposeBag)
    }
    
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
