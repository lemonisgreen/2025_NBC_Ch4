//
//  MainViewModel.swift
//  SherlDog
//
//  Created by 김재우 on 6/13/25.
//

import RxSwift
import RxCocoa
import CoreLocation
import RxCoreLocation

final class MainViewModel {
    
    let startTracking = PublishRelay<Void>()
    let stopTracking = PublishRelay<Void>()
    let isTracking = BehaviorRelay<Bool>(value: false)

    let coordinates = BehaviorRelay<[CLLocationCoordinate2D]>(value: [])

    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()

    init() {
        setupLocationUpdates()
        bindInputs()
    }
    
    private func bindInputs() {
        startTracking
            .subscribe(onNext: { [weak self] in
                self?.isTracking.accept(true)
            })
            .disposed(by: disposeBag)
        
        stopTracking
            .subscribe(onNext: { [weak self] in
                self?.isTracking.accept(false)
                self?.coordinates.accept([])
            })
            .disposed(by: disposeBag)
    }

    private func setupLocationUpdates() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
//        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false

        locationManager.rx.didUpdateLocations
            .throttle(.seconds(2), latest: true, scheduler: MainScheduler.instance)
            .compactMap { $0.locations.last }
            .subscribe(onNext: { [weak self] newLocation in
                guard let self = self else { return }
                let current = newLocation.coordinate
                let previous = self.coordinates.value.last

                if let prev = previous {
                    let distance = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
                        .distance(from: CLLocation(latitude: current.latitude, longitude: current.longitude))

                    if distance >= 10 && distance < 50 {
                        self.coordinates.accept(self.coordinates.value + [current])
                    }
                } else {
                    self.coordinates.accept(self.coordinates.value + [current])
                }
            })
            .disposed(by: disposeBag)
    }
}
