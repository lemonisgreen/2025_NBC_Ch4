//
//  OnboardingViewController.swift
//  SherlDog
//
//  Created by JIN LEE on 9/13/25.
//

import UIKit
import Lottie
import SnapKit
import RxSwift

class OnboardingViewController: UIViewController {
    
    private let viewModel = OnboardingViewModel()
    private let disposeBag = DisposeBag()
    
    private var progressBars: [UIView] = []
    private let progressBarStackView = UIStackView()
    
    private let introduceLabel = UILabel()
    
    private var animationView = LottieAnimationView()
    
    private let skipButton = ButtonFactory.makeButton(type: .sub, title: "건너뛰기")
    private let nextButton = ButtonFactory.makeButton(type: .main, title: "다음으로")
    private let buttonStackView = UIStackView()
    private let startButton = ButtonFactory.makeButton(type: .main, title: "시작하기")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        bind()
        setupUI()
        configureUI()
    }
    
    private func updateProgressBars(for step: Int) {
        for (index, bar) in progressBars.enumerated() {
            bar.backgroundColor = index <= step ? .keycolorPrimary1 : .gray200
        }
    }
    
    private func updateButtons(for step: Int) {
        let isLast = step == viewModel.stepCount - 1
        nextButton.isHidden = isLast
        startButton.isHidden = !isLast
    }
    
    private func goToLogin() {
        let loginVC = LoginViewController()
        let navController = UINavigationController(rootViewController: loginVC)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = navController
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }
    
    func bind() {
        viewModel.currentText
            .observe(on: MainScheduler.instance)
            .bind(to: introduceLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.currentStep
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] step in
                self?.updateProgressBars(for: step)
                self?.updateButtons(for: step)
            })
            .disposed(by: disposeBag)
        
        viewModel.currentLottieName
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] lottieName in
                guard let self = self else { return }
                self.animationView.animation = LottieAnimation.named(lottieName)
                self.animationView.loopMode = .loop
                self.animationView.play()
                
                // 높이 비율 계산 및 업데이트
                let deviceWidth = UIScreen.main.bounds.width
                let baseWidth: CGFloat = 375
                let baseHeight: CGFloat = (lottieName == "Onboarding1") ? 346 : 435
                let height = baseHeight * (deviceWidth / baseWidth)
                self.animationView.snp.updateConstraints {
                    $0.height.equalTo(height)
                }
                
                self.view.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
        
        skipButton.rx.tap
            .bind { [weak self] in
                self?.viewModel.completeOnboarding()
                self?.goToLogin()
            }.disposed(by: disposeBag)
        
        nextButton.rx.tap
            .bind { [weak self] in self?.viewModel.goToNextStep() }
            .disposed(by: disposeBag)
        
        startButton.rx.tap
            .bind { [weak self] in
                self?.viewModel.completeOnboarding()
                self?.goToLogin()
            }.disposed(by: disposeBag)
    }
    
    private func setupUI() {
        
        [
            skipButton,
            nextButton
        ].forEach { buttonStackView.addArrangedSubview($0)}
        
        self.view.addSubviews([
            progressBarStackView,
            introduceLabel,
            animationView,
            buttonStackView,
            startButton
        ])
        
        for i in 0..<viewModel.stepCount {
            let bar = UIView()
            bar.layer.cornerRadius = 1.5
            bar.backgroundColor = (i == 0) ? .keycolorPrimary1 : .gray200
            progressBars.append(bar)
            progressBarStackView.addArrangedSubview(bar)
        }
        
        progressBarStackView.axis = .horizontal
        progressBarStackView.distribution = .fillEqually
        progressBarStackView.spacing = 4
        
        introduceLabel.font = .loginScreen
        introduceLabel.textAlignment = .center
        introduceLabel.numberOfLines = 0
        
        animationView.contentMode = .scaleAspectFit
        
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 8
        
        startButton.isHidden = true
    }
    
    private func configureUI() {
        
        progressBarStackView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(24)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(3)
        }
        
        introduceLabel.snp.makeConstraints {
            $0.top.equalTo(progressBarStackView.snp.bottom).offset(12 + 28 + 24)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        animationView.snp.makeConstraints {
            $0.top.equalTo(introduceLabel.snp.bottom).offset(50)
            $0.leading.trailing.equalToSuperview().inset(8)
        }
        
        buttonStackView.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(52)
        }
        
        skipButton.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(134)
        }
        
        nextButton.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(201)
        }
        
        startButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(52)
        }
    }
}


