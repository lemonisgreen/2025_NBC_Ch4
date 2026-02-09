//
//  WalkSession.swift
//  SherlDog
//
//  Created by JIN LEE on 2/3/26.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa
import RxCoreLocation
import CoreMotion
import NMapsMap

final class WalkSession {

    struct Config {
        let distanceFilter: CLLocationDistance = 10
        let throttleSeconds: Int = 2
        let minAppendMeters: CLLocationDistance = 5
        let maxAppendMeters: CLLocationDistance = 50
    }

    struct State {
        var isActive: Bool
        var startDate: Date?
        var endDate: Date?
        var elapsedSeconds: Int
        var steps: Int
        var distanceMeters: Double
        var coordinates: [CLLocationCoordinate2D]
    }

    // Output
    let state: BehaviorRelay<State>
    let fullSideOfCourse = PublishRelay<NMGLatLngBounds>() 

    private let locationManager: CLLocationManager
    private let pedometer: CMPedometer
    private let config: Config
    private let disposeBag = DisposeBag()

    private var timerDisposable: Disposable?

    init(
        locationManager: CLLocationManager,
        pedometer: CMPedometer = CMPedometer(),
        config: Config = Config()
    ) {
        self.locationManager = locationManager
        self.pedometer = pedometer
        self.config = config

        self.state = BehaviorRelay(value: State(
            isActive: false,
            startDate: nil,
            endDate: nil,
            elapsedSeconds: 0,
            steps: 0,
            distanceMeters: 0,
            coordinates: []
        ))

        setupLocation()
        bindLocationUpdates()
    }

    func start() {
        let now = Date()
        var s = state.value
        s.isActive = true
        s.startDate = now
        s.endDate = nil
        s.elapsedSeconds = 0
        s.steps = 0
        s.distanceMeters = 0
        s.coordinates = []
        state.accept(s)

        pedometer.startUpdates(from: now) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            var s = self.state.value
            s.steps = data.numberOfSteps.intValue
            s.distanceMeters = data.distance?.doubleValue ?? 0
            self.state.accept(s)
        }

        timerDisposable?.dispose()
        timerDisposable = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                guard let start = self.state.value.startDate, self.state.value.isActive else { return }
                var s = self.state.value
                s.elapsedSeconds = Int(Date().timeIntervalSince(start))
                self.state.accept(s)
            })
    }

    func stop() {
        pedometer.stopUpdates()
        timerDisposable?.dispose()
        timerDisposable = nil

        var s = state.value
        s.isActive = false
        s.endDate = Date()
        state.accept(s)

        if s.coordinates.count < 2 {
            fullSideOfCourse.accept(NMGLatLngBounds())
        } else {
            fullSideOfCourse.accept(fetchFullSide(from: s.coordinates))
        }
    }

    private func setupLocation() {
        locationManager.distanceFilter = config.distanceFilter
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
    }

    private func bindLocationUpdates() {
        locationManager.rx.didUpdateLocations
            .throttle(.seconds(config.throttleSeconds), latest: true, scheduler: MainScheduler.instance)
            .compactMap { $0.locations.last }
            .subscribe(onNext: { [weak self] newLocation in
                guard let self else { return }
                guard self.state.value.isActive else { return }

                let current = newLocation.coordinate
                let previous = self.state.value.coordinates.last

                if let prev = previous {
                    let distance = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
                        .distance(from: CLLocation(latitude: current.latitude, longitude: current.longitude))

                    guard distance >= self.config.minAppendMeters, distance < self.config.maxAppendMeters else { return }
                }

                var s = self.state.value
                s.coordinates.append(current)
                self.state.accept(s)
            })
            .disposed(by: disposeBag)
    }

    private func fetchFullSide(from coords: [CLLocationCoordinate2D]) -> NMGLatLngBounds {
        let latLngs = coords.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) }
        return NMGLatLngBounds(latLngs: latLngs)
    }
}

extension WalkSession.State {
    static let initial = WalkSession.State(
        isActive: false,
        startDate: nil,
        endDate: nil,
        elapsedSeconds: 0,
        steps: 0,
        distanceMeters: 0,
        coordinates: []
    )
}
