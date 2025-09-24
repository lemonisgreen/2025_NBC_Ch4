//
//  OnboardingViewModel.swift
//  SherlDog
//
//  Created by JIN LEE on 9/15/25.
//

import RxSwift
import RxCocoa
import Foundation

final class OnboardingViewModel {
    
    let model = OnboardingModel()
    let stepCount: Int
    let currentStep = BehaviorRelay<Int>(value: 0)
    
    init() {
        stepCount = model.steps.count
    }
    
    var currentText: Observable<String> {
        currentStep.map { self.model.steps[$0].text }
    }
    
    var currentLottieName: Observable<String> {
        currentStep.map { self.model.steps[$0].lottieName }
    }
    
    func goToNextStep() {
        let next = min(currentStep.value + 1, stepCount - 1)
        currentStep.accept(next)
    }
    
    func completeOnboarding() {
           UserDefaults.standard.set(true, forKey: "onboardingCompleted")
       }
}
