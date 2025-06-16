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

    // MARK: Output
    let coordinates = BehaviorRelay<[CLLocationCoordinate2D]>(value: [])

    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()

    init() {
        setupLocationUpdates()
    }

    private func setupLocationUpdates() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        locationManager.rx.didUpdateLocations
            .compactMap { $0.locations.last?.coordinate }
            .withLatestFrom(coordinates) { new, current in
                var updated = current
                updated.append(new)
                return updated
            }
            .bind(to: coordinates)
            .disposed(by: disposeBag)

        // 가상 좌표 생성 (시뮬레이션)
        startTracking
            .flatMapLatest { _ in
                Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
                    .map { index in
                        CLLocationCoordinate2D(latitude: 37.5665 + Double(index) * 0.0001,
                                               longitude: 126.9780 + Double(index) * 0.0001)
                    }
                    .withLatestFrom(self.coordinates) { new, current in
                        var updated = current
                        updated.append(new)
                        return updated
                    }
                    .take(100)
            }
            .bind(to: coordinates)
            .disposed(by: disposeBag)
    }
}
