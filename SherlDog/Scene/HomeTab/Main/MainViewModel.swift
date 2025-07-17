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
import NMapsMap

final class MainViewModel {
    
    let startTracking = PublishRelay<Void>()
    let stopTracking = PublishRelay<Void>()
    let fullSideOfCourse = PublishRelay<NMGLatLngBounds>()
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
                guard let self else { return }
                self.isTracking.accept(false)
                let coords = self.coordinates.value
                if coords.count < 2 {
                    self.fullSideOfCourse.accept(NMGLatLngBounds())
                } else {
                    self.fullSideOfCourse.accept(self.fetchFullSide())
                }
            })
            .disposed(by: disposeBag)
    }

    private func setupLocationUpdates() {
        locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()

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
                    
                    if self.isTracking.value && distance >= 5 && distance < 50 {
                        self.coordinates.accept(self.coordinates.value + [current])
                    }
                } else if self.isTracking.value {
                    self.coordinates.accept(self.coordinates.value + [current])
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchFullSide() -> NMGLatLngBounds {
        var latLng = [NMGLatLng]()
        
        self.coordinates.value.forEach {
            latLng.append(NMGLatLng(lat: $0.latitude, lng: $0.longitude))
        }
        
        return NMGLatLngBounds(latLngs: latLng)
    }
}
