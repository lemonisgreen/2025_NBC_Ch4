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
        let weatherState: BehaviorRelay<WeatherState>
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
    private let weatherState = BehaviorRelay<WeatherState>(value: .initial)
    
    // MARK: - Dependencies
    
    private let weatherSession: WeatherSession
    private let walkSession: WalkSession
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    
    init(locationManager: CLLocationManager) {
        self.weatherSession = WeatherSession(locationManager: locationManager)
        self.walkSession = WalkSession(locationManager: locationManager)
        
        self.input = Input(
            startTracking: startTracking,
            stopTracking: stopTracking,
            reloadClues: reloadClues
        )
        
        self.output = Output(
            fullSideOfCourse: fullSideOfCourse,
            clues: clues,
            sessionState: sessionState,
            weatherState: weatherState
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
                self?.weatherSession.resumeWeatherUpdates()
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
        
        weatherSession.makeWeatherState()
            .filter { [weak self] state in
                guard let self else { return false }
                
                return state.hourlyWeather.contains { $0.condition.isRainRelated } &&
                self.sessionState.value.isActive
            }
            .do(onNext: { [weak self] state in
                Task { [weak self] in
                    guard let self else { return }
                    
                    let granted = await NotificationManager.shared.requestAuthorization()
                    guard granted else { return }
                    
                    guard let rainWeather = state.hourlyWeather.first(where: \.condition.isRainRelated) else { return }
                    
                    let diff = rainWeather.date.timeIntervalSince(Date()) / 60
                    NotificationManager.shared.scheduleNotification(rainAfter: (diff))
                    self.weatherSession.pauseWeatherUpdates()
                }
            })
            .bind(to: weatherState)
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
        guard let userId = AuthSession.currentAppUserId,
                 !userId.isEmpty else {
               self.clues.accept([])
               return
           }
        
        FirestoreManager.shared.fetchQuery(
            FirestoreQuery<ClueModel>(
                collection: .clues,
                type: .whereField(field: "userID", value: userId)
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

