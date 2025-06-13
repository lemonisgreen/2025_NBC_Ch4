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

    private var isLoggingIn = false
    private let disposeBag = DisposeBag()

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

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupUI()
        setupConstraints()
        setupSplashView()
        setupKakaoLogin()
        checkAutoLogin()
        bindUI()
        navigationItem.backButtonTitle = ""
    }

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

        setupSocialButtonsStack()
    }

    private func setupSocialButtonsStack() {
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

    private func setupKakaoLogin() {
        KakaoLoginManager.shared.delegate = self
    }

    private func checkAutoLogin() {
        if KakaoLoginManager.shared.isLoggedIn() {
            KakaoLoginManager.shared.validateToken { [weak self] isValid in
                DispatchQueue.main.async {
                    if isValid {
                        self?.navigateToNextScreen()
                    } else {
                        KakaoLoginManager.shared.logout()
                    }
                }
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        isLoggingIn = loading
        loading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
        view.isUserInteractionEnabled = !loading
    }

    private func navigateToNextScreen() {
        navigationController?.pushViewController(PetProfileViewController(), animated: true)
    }

    private func showLoginError(message: String) {
        let alert = UIAlertController(
            title: "로그인 실패",
            message: "다시 로그인 해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func showComingSoonAlert(for provider: String) {
        let alert = UIAlertController(
            title: "준비 중입니다",
            message: "\(provider) 로그인은 곧 지원될 예정입니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func bindUI() {
        kakaoButton.rx.tap
            .bind { [weak self] in self?.performKakaoLogin() }
            .disposed(by: disposeBag)

        naverButton.rx.tap
            .bind { [weak self] in self?.showComingSoonAlert(for: "네이버") }
            .disposed(by: disposeBag)

        googleButton.rx.tap
            .bind { [weak self] in self?.performGoogleLogin() }
            .disposed(by: disposeBag)

        appleButton.rx.tap
            .bind { [weak self] in self?.showComingSoonAlert(for: "애플") }
            .disposed(by: disposeBag)

        facebookButton.rx.tap
            .bind { [weak self] in self?.showComingSoonAlert(for: "페이스북") }
            .disposed(by: disposeBag)
    }

    private func performKakaoLogin() {
        guard !isLoggingIn else { return }
        setLoading(true)

        KakaoLoginManager.shared.login { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)

                switch result {
                case .success(let user):
                    let userInfo = KakaoUserInfo(from: user)
                    UserDefaults.standard.set(true, forKey: "isKakaoLoggedIn")
                    UserDefaults.standard.set(userInfo.nickname, forKey: "userNickname")
                    UserDefaults.standard.set(userInfo.email, forKey: "userEmail")
                    self?.navigateToNextScreen()
                case .failure(let error):
                    if case .userCancelled = error { return }
                    self?.showLoginError(message: error.localizedDescription)
                }
            }
        }
    }

    private func performGoogleLogin() {
        guard !isLoggingIn else { return }
        setLoading(true)

        guard let rootVC = self.view.window?.rootViewController else {
            setLoading(false)
            showLoginError(message: "화면 전환 컨트롤러를 찾을 수 없습니다.")
            return
        }

        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootVC,
            hint: nil,
            additionalScopes: []
        ) { [weak self] signInResult, error in
            guard let self = self else { return }
            self.setLoading(false)

            if let error = error {
                self.showLoginError(message: error.localizedDescription)
                return
            }

            guard
                let user = signInResult?.user,
                let idToken = user.idToken?.tokenString
            else {
                self.showLoginError(message: "인증 토큰을 가져오지 못했습니다")
                return
            }

            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.showLoginError(message: error.localizedDescription)
                    return
                }
                self.navigateToNextScreen()
            }
        }
    }
}

extension LoginViewController: KakaoLoginManagerDelegate {
    func kakaoLoginDidSucceed(user: KakaoSDKUser.User) {
        let _ = KakaoUserInfo(from: user)
    }

    func kakaoLoginDidFail(error: KakaoLoginError) {
        print("카카오 로그인 실패 (Delegate): \(error.localizedDescription)")
    }
}

extension LoginViewController {
    private func dismissSplashView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.splashView.alpha = 0
        }) { _ in
            self.splashView.removeFromSuperview()
        }
    }
}
