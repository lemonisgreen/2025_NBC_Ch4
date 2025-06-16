//
//  LoginViewController.swift
//  SherlDog
//
//  Created by 최영락 on 6/5/25.
//

import UIKit
import SnapKit
import KakaoSDKUser
import FirebaseCore
import GoogleSignIn
import FirebaseAuth
import RxSwift
import RxCocoa

class LoginViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let viewModel = LoginViewModel()

    // MARK: - UI Components
    private let splashView = SplashView()
    private let logo = UIImageView()
    private let helloLabel = UILabel()
    private let helloLabel2 = UILabel()
    private let joinImage = UIImageView()
    private let kakaoButton = UIButton()
    private let naverButton = UIButton()
    private let googleButton = UIButton()
    private let appleButton = UIButton()
    private let facebookButton = UIButton()
    private let orLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupUI()
        setupConstraints()
        setupSplashView()
        bindViewModel()
        navigationItem.backButtonTitle = ""
    }

    // MARK: - UI Setup
    private func configureUI() {
        view.backgroundColor = .keycolorBackground

        logo.image = UIImage(named: "bigLogo")
        logo.contentMode = .scaleAspectFit

        helloLabel.text = "반가워요!"
        helloLabel.font = UIFont(name: "EF_jejudoldam", size: 24)
        helloLabel.textAlignment = .center

        helloLabel2.text = "멍탐정과 함께 오늘의 수사를 시작해볼까요?"
        helloLabel2.font = UIFont(name: "EF_jejudoldam", size: 18)
        helloLabel2.textAlignment = .center

        joinImage.image = UIImage(named: "join")
        joinImage.contentMode = .scaleAspectFit

        orLabel.text = "또는"
        orLabel.font = UIFont(name: "Pretendard", size: 12)
        orLabel.textAlignment = .center

        kakaoButton.setImage(.kakao, for: .normal)
        naverButton.setImage(.naver, for: .normal)
        googleButton.setImage(.google, for: .normal)
        appleButton.setImage(.apple, for: .normal)
        facebookButton.setImage(.facebook, for: .normal)

        loadingIndicator.color = .systemBlue
        loadingIndicator.hidesWhenStopped = true
    }

    private func setupUI() {
        [logo, helloLabel, helloLabel2, joinImage, orLabel,
         kakaoButton, naverButton, googleButton, appleButton, facebookButton, loadingIndicator]
            .forEach { view.addSubview($0) }
    }

    private func setupConstraints() {
        logo.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(140)
        }

        helloLabel.snp.makeConstraints {
            $0.top.equalTo(logo.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }

        helloLabel2.snp.makeConstraints {
            $0.top.equalTo(helloLabel.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
        }

        joinImage.snp.makeConstraints {
            $0.top.equalTo(helloLabel2.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(80)
            $0.width.equalToSuperview().multipliedBy(0.75)
        }

        naverButton.snp.makeConstraints {
            $0.top.equalTo(joinImage.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(54)
            $0.width.equalToSuperview().multipliedBy(0.85)
        }

        kakaoButton.snp.makeConstraints {
            $0.top.equalTo(naverButton.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(54)
            $0.width.equalToSuperview().multipliedBy(0.85)
        }

        orLabel.snp.makeConstraints {
            $0.top.equalTo(kakaoButton.snp.bottom).offset(24)
            $0.centerX.equalToSuperview()
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        let stack = UIStackView(arrangedSubviews: [googleButton, appleButton, facebookButton])
        stack.axis = .horizontal
        stack.spacing = 20
        stack.alignment = .center
        stack.distribution = .equalSpacing

        view.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalTo(orLabel.snp.bottom).offset(28)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(56)
        }

        [googleButton, appleButton, facebookButton].forEach {
            $0.snp.makeConstraints {
                $0.size.equalTo(48)
            }
        }
    }

    private func setupSplashView() {
        view.addSubview(splashView)
        splashView.frame = view.bounds
        view.bringSubviewToFront(splashView)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.dismissSplashView()
        }
    }

    private func dismissSplashView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.splashView.alpha = 0
        }) { _ in
            self.splashView.removeFromSuperview()
        }
    }

    // MARK: - Bindings
    private func bindViewModel() {
        // Input - 버튼 탭을 ViewModel에 전달
        kakaoButton.rx.tap
            .bind(to: viewModel.input.kakaoTap)
            .disposed(by: disposeBag)

        naverButton.rx.tap
            .bind(to: viewModel.input.naverTap)
            .disposed(by: disposeBag)

        googleButton.rx.tap
            .bind(to: viewModel.input.googleTap)
            .disposed(by: disposeBag)

        appleButton.rx.tap
            .bind(to: viewModel.input.appleTap)
            .disposed(by: disposeBag)

        facebookButton.rx.tap
            .bind(to: viewModel.input.facebookTap)
            .disposed(by: disposeBag)

        // Output - ViewModel의 상태를 UI에 반영
        // Driver 사용 (메인 스레드 보장, 에러 없음, 공유됨)
        viewModel.output.isLoading
            .drive(loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        // Signal 사용 (이벤트성, 메인 스레드 보장)
        viewModel.output.navigate
            .emit(onNext: { [weak self] in
                self?.navigateToNextScreen()
            })
            .disposed(by: disposeBag)

        viewModel.output.showError
            .emit(onNext: { [weak self] message in
                self?.showErrorAlert(message: message)
            })
            .disposed(by: disposeBag)

        viewModel.output.showAlert
            .emit(onNext: { [weak self] message in
                self?.showInfoAlert(message: message)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation & Alert Methods
    private func navigateToNextScreen() {
        let petProfileVC = PetProfileViewController()
        navigationController?.pushViewController(petProfileVC, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "로그인 실패",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func showInfoAlert(message: String) {
        let alert = UIAlertController(
            title: "준비 중입니다",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
