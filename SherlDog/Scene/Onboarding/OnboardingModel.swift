//
//  OnboardingModel.swift
//  SherlDog
//
//  Created by JIN LEE on 9/15/25.
//

struct OnboardingStep {
    let text: String
    let lottieName: String
}

struct OnboardingModel {
    let steps: [OnboardingStep] = [
        OnboardingStep(
            text: "반려견은 멍탐정,\n당신은 멍탐정의 조수!\n매일의 산책,\n오늘은 수사로 떠나봐요.",
            lottieName: "Onboarding1"),
        OnboardingStep(
            text: "멍탐정의 산책길!\n수사 중 발견한 특별한 순간을\n단서로 저장해 보세요.",
            lottieName: "Onboarding2"),
        OnboardingStep(
            text: "수사가 끝나면 경로와 운동데이터,\n시간이 오늘의 수사일지에\n자동으로 기록돼요!",
            lottieName: "Onboarding3")
    ]
}
