//
//  DataTrackingViewModel.swift
//  SherlDog
//
//  Created by 전원식 on 6/17/25.
//
import UIKit
import RxSwift
import RxCocoa
import CoreMotion

class DataTrackingViewModel {
    
    let numberOfSteps = BehaviorRelay<Int>(value: 0)
    let distance = BehaviorRelay<Double>(value: 0.0)
    let startDate = BehaviorRelay<Date?>(value: nil)
    let endDate = BehaviorRelay<Date?>(value: nil)
    let trackingActive = BehaviorRelay<Bool>(value: false)
    let capturedImage = BehaviorRelay(value: UIImage())

    private let pedometer = CMPedometer()
    
    func startTracking() {
        let now = Date()
        startDate.accept(now)
        trackingActive.accept(true)
        
        pedometer.startUpdates(from: now) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            
            self.numberOfSteps.accept(data.numberOfSteps.intValue)
            self.distance.accept(data.distance?.doubleValue ?? 0.0)
        }
    }
    
    func stopTracking() {
        trackingActive.accept(false)
        pedometer.stopUpdates()
        endDate.accept(Date())
    }
}

