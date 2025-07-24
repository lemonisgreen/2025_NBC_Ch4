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
    
    struct Input {
        let startTracking: PublishRelay<Void>
        let stopTracking: PublishRelay<Void>
    }

    struct Output {
        let fullSideOfCourse: PublishRelay<NMGLatLngBounds>
        let isTracking: BehaviorRelay<Bool>
        let coordinates: BehaviorRelay<[CLLocationCoordinate2D]>
    }

    let input: Input
    let output: Output

    private let startTracking = PublishRelay<Void>()
    private let stopTracking = PublishRelay<Void>()
    private let fullSideOfCourse = PublishRelay<NMGLatLngBounds>()
    private let isTracking = BehaviorRelay<Bool>(value: false)
    private let coordinates = BehaviorRelay<[CLLocationCoordinate2D]>(value: [])

    private let locationManager: CLLocationManager
    private let disposeBag = DisposeBag()

    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        self.input = Input(startTracking: startTracking, stopTracking: stopTracking)
        self.output = Output(fullSideOfCourse: fullSideOfCourse, isTracking: isTracking, coordinates: coordinates)

        setupLocationUpdates()
        bindInputs()
    }
    
    private func bindInputs() {
        input.startTracking
            .subscribe(onNext: { [weak self] in
                self?.output.isTracking.accept(true)
            })
            .disposed(by: disposeBag)
        
        input.stopTracking
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.output.isTracking.accept(false)
                let coords = self.output.coordinates.value
                if coords.count < 2 {
                    self.output.fullSideOfCourse.accept(NMGLatLngBounds())
                } else {
                    self.output.fullSideOfCourse.accept(self.fetchFullSide())
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
                let previous = self.output.coordinates.value.last

                if let prev = previous {
                    let distance = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
                        .distance(from: CLLocation(latitude: current.latitude, longitude: current.longitude))
                    
                    if self.output.isTracking.value && distance >= 5 && distance < 50 {
                        self.output.coordinates.accept(self.output.coordinates.value + [current])
                    }
                } else if self.output.isTracking.value {
                    self.output.coordinates.accept(self.output.coordinates.value + [current])
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchFullSide() -> NMGLatLngBounds {
        var latLng = [NMGLatLng]()
        
        self.output.coordinates.value.forEach {
            latLng.append(NMGLatLng(lat: $0.latitude, lng: $0.longitude))
        }
        
        return NMGLatLngBounds(latLngs: latLng)
    }
}
