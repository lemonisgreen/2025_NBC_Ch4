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
    // MARK: Input
    let startTracking = PublishRelay<Void>()
    let stopTracking = PublishRelay<Void>()

    // MARK: Output
    let coordinates = BehaviorRelay<[CLLocationCoordinate2D]>(value: [])

    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()
    private var trackingDisposable: Disposable?

    init() {
        setupLocationUpdates()
    }

    private func setupLocationUpdates() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        locationManager.rx.didUpdateLocations
            .compactMap { $0.locations.last }
            .subscribe(onNext: { [weak self] newLocation in
                guard let self = self else { return }
                let current = newLocation.coordinate
                let previous = self.coordinates.value.last

                if let prev = previous {
                    let distance = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
                        .distance(from: CLLocation(latitude: current.latitude, longitude: current.longitude))

                    if distance < 30 {
                        self.coordinates.accept(self.coordinates.value + [current])
                    }
                } else {
                    self.coordinates.accept(self.coordinates.value + [current])
                }
            })
            .disposed(by: disposeBag)
    }
}
