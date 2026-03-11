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
    private let headerLabel = UILabel()
    private let logo = UIImageView()
    private let helloLabel = UILabel()
    private let helloLabel2 = UILabel()
    private let joinImage = UIImageView()
    private let kakaoButton = UIButton()
    private let googleButton = UIButton()
    private let appleButton = UIButton()
    private let loadingIndicator = CustomLoadingIndicator()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupUI()
        setupConstraints()
        bindViewModel()
        navigationItem.backButtonTitle = ""
    }
    
    // MARK: - UI Setup
    private func configureUI() {
        view.backgroundColor = .keycolorTertiaryBG
        
        headerLabel.text = SDLiteral.LoginView.headerLabel
        headerLabel.font = .body1
        headerLabel.textColor = .textPrimary
        
        logo.image = UIImage(named: "bigLogo")
        logo.contentMode = .scaleAspectFit
        
        helloLabel.text = SDLiteral.LoginView.helloLabelLarge
        helloLabel.font = .loginScreen
        helloLabel.textAlignment = .center
        helloLabel.textColor = .textPrimary
        
        helloLabel2.text = SDLiteral.LoginView.helloLabelSmall
        helloLabel2.font = .cardTitle2
        helloLabel2.textAlignment = .center
        helloLabel2.textColor = .textPrimary
        
        joinImage.image = UIImage(named: "join")
        joinImage.contentMode = .scaleAspectFit
        
        kakaoButton.setImage(.kakao, for: .normal)
        googleButton.setImage(.google, for: .normal)
        appleButton.setImage(.apple, for: .normal)
    }
    
    private func setupUI() {
        [headerLabel, logo, helloLabel, helloLabel2, joinImage,
         kakaoButton,  googleButton, appleButton, loadingIndicator]
            .forEach { view.addSubview($0) }
    }
    
    private func setupConstraints() {
        headerLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.centerX.equalToSuperview()
        }
        
        logo.snp.makeConstraints {
            $0.top.equalTo(headerLabel.snp.bottom).offset(49)
            $0.leading.equalToSuperview().inset(112)
            $0.trailing.equalToSuperview().inset(127)
            $0.height.equalTo(logo.snp.width).multipliedBy(160.0/136.0)
        }

        helloLabel.snp.makeConstraints {
            $0.top.equalTo(logo.snp.bottom).offset(28)
            $0.horizontalEdges.equalToSuperview().inset(12)
            $0.centerX.equalToSuperview()
        }

        helloLabel2.snp.makeConstraints {
            $0.top.equalTo(helloLabel.snp.bottom).offset(4)
            $0.horizontalEdges.equalToSuperview().inset(12)
            $0.centerX.equalToSuperview()
        }
        
        joinImage.snp.makeConstraints {
            $0.bottom.equalTo(appleButton.snp.top).offset(-12)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(54)
            $0.width.equalToSuperview().multipliedBy(0.75)
            $0.top.greaterThanOrEqualTo(helloLabel2.snp.bottom).offset(24)
        }
        
        appleButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(52)
            $0.width.equalToSuperview().multipliedBy(0.85)
            $0.bottom.equalTo(kakaoButton.snp.top).offset(-8)
            $0.width.lessThanOrEqualTo(360)
        }
        
        kakaoButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(52)
            $0.width.equalToSuperview().multipliedBy(0.85)
            $0.bottom.equalTo(googleButton.snp.top).offset(-8)
            $0.width.lessThanOrEqualTo(360)
        }

        googleButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(52)
            $0.width.equalToSuperview().multipliedBy(0.85)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(32)
            $0.width.lessThanOrEqualTo(360)
        }

        loadingIndicator.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    // MARK: - Bindings
    private func bindViewModel() {
        // Input - 버튼 탭을 ViewModel에 전달
        kakaoButton.rx.tap
            .bind(to: viewModel.input.kakaoTap)
            .disposed(by: disposeBag)
        
        googleButton.rx.tap
            .bind(to: viewModel.input.googleTap)
            .disposed(by: disposeBag)
        
        appleButton.rx.tap
            .bind(to: viewModel.input.appleTap)
            .disposed(by: disposeBag)
        
        // Output - ViewModel의 상태를 UI에 반영
        viewModel.output.isLoading
            .map { !$0 }
            .drive(loadingIndicator.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.output.navigateToPetProfile
            .emit(onNext: { [weak self] in
                let petProfileVC = PetProfileViewController()
                self?.navigationController?.pushViewController(petProfileVC, animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.navigateToMain
            .emit(onNext: { _ in
                let mainVC = BottomTabBarController()
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let delegate = windowScene.delegate as? SceneDelegate,
                   let window = delegate.window {
                    window.rootViewController = mainVC
                    window.makeKeyAndVisible()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.output.showError
            .emit(onNext: { [weak self] message in
                self?.showErrorAlert(message: message)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation, Alert
    private func navigateToNextScreen() {
        // 현재 사용자가 펫 프로필을 가지고 있는지 확인
        guard let userId = AuthSession.currentAppUserId else { return }
        
        FirestoreManager.shared.fetchQuery(
            FirestoreQuery<PetProfile>(
                collection: .petProfile,
                type: .whereField(field: "userId", value: userId)
            )
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] profiles in
                if profiles.isEmpty {
                    // 펫 프로필이 없으면 등록 화면으로
                    let petProfileVC = PetProfileViewController()
                    self?.navigationController?.pushViewController(petProfileVC, animated: true)
                } else {
                    // 펫 프로필이 있으면 메인 화면으로
                    let mainVC = BottomTabBarController()
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let delegate = windowScene.delegate as? SceneDelegate,
                       let window = delegate.window {
                        window.rootViewController = mainVC
                        window.makeKeyAndVisible()
                    }
                }
            },
            onFailure: { [weak self] error in
                print("펫 프로필 확인 실패: \(error)")
                // 실패 시 안전하게 펫 프로필 화면으로
                let petProfileVC = PetProfileViewController()
                self?.navigationController?.pushViewController(petProfileVC, animated: true)
            }
        )
        .disposed(by: disposeBag)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: SDLiteral.LoginView.loginErrorMessageTitle,
            message: SDLiteral.LoginView.loginErrorMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: SDLiteral.AlertMessage.confirm, style: .default))
        present(alert, animated: true)
    }
}
