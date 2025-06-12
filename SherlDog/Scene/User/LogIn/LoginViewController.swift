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

class LoginViewController: UIViewController {
    
    // MARK: - Constants
    private struct Constants {
        static let splashDuration: TimeInterval = 2.0
        static let animationDuration: TimeInterval = 0.5
        static let helloLabelSize: CGFloat = 24
        static let helloLabel2Size: CGFloat = 18
        static let orLabelSize: CGFloat = 12
        static let logoHeight: CGFloat = 200
        static let buttonHeight: CGFloat = 54
        static let socialButtonSize: CGFloat = 50
        static let joinImageHeight: CGFloat = 96
        static let buttonWidthMultiplier: CGFloat = 0.85
        static let imageWidthMultiplier: CGFloat = 0.8
    }
    
    // MARK: - Properties
    private var isLoggingIn = false
    
    // MARK: - 컴포넌트
    let splashView = SplashView()
    
    private let logo: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "bigLogo")
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    private let helloLabel: UILabel = {
        let label = UILabel()
        label.text = "반가워요!"
        label.font = UIFont(name: "EF_jejudoldam", size: Constants.helloLabelSize)
        label.textAlignment = .center
        return label
    }()
    
    private let helloLabel2: UILabel = {
        let label = UILabel()
        label.text = "멍탐정과 함께 오늘의 수사를 시작해볼까요?"
        label.font = UIFont(name: "EF_jejudoldam", size: Constants.helloLabel2Size)
        label.textAlignment = .center
        return label
    }()
    
    private let joinImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "join")
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    private lazy var kakaoButton: UIButton = {
        let button = UIButton()
        button.setImage(.kakao, for: .normal)
        button.addTarget(self, action: #selector(kakaoLoginTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var naverButton: UIButton = {
        let button = UIButton()
        button.setImage(.naver, for: .normal)
        button.addTarget(self, action: #selector(naverLoginTapped), for: .touchUpInside)
        return button
    }()
    
    private let orLabel: UILabel = {
        let label = UILabel()
        label.text = "또는"
        label.font = UIFont(name: "Pretendard", size: Constants.orLabelSize)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var googleButton: UIButton = {
        let button = UIButton()
        button.setImage(.google, for: .normal)
        button.addTarget(self, action: #selector(googleLoginTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var appleButton: UIButton = {
        let button = UIButton()
        button.setImage(.apple, for: .normal)
        button.addTarget(self, action: #selector(appleLoginTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var facebookButton: UIButton = {
        let button = UIButton()
        button.setImage(.facebook, for: .normal)
        button.addTarget(self, action: #selector(facebookLoginTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Loading Indicator
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemBlue
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupSplashView()
        setupKakaoLogin()
        checkAutoLogin()
        navigationItem.backButtonTitle = ""
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor.keycolorBackground
        
        [logo, helloLabel, helloLabel2, joinImage, orLabel,
         naverButton, kakaoButton, googleButton, appleButton, facebookButton, loadingIndicator]
            .forEach { view.addSubview($0) }
    }
    
    private func setupSplashView() {
        view.addSubview(splashView)
        view.bringSubviewToFront(splashView)
        splashView.frame = view.bounds
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.splashDuration) {
            self.dismissSplashView()
        }
    }
    
    private func setupKakaoLogin() {
        KakaoLoginManager.shared.delegate = self
    }
    
    private func checkAutoLogin() {
        // 이미 로그인된 상태인지 확인
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
    
    private func setupConstraints() {
        logo.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(40)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(Constants.logoHeight)
        }
        
        helloLabel.snp.makeConstraints {
            $0.top.equalTo(logo.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        
        helloLabel2.snp.makeConstraints {
            $0.top.equalTo(helloLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }
        
        joinImage.snp.makeConstraints {
            $0.top.equalTo(helloLabel2.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(Constants.joinImageHeight)
            $0.width.equalToSuperview().multipliedBy(Constants.imageWidthMultiplier)
        }
        
        naverButton.snp.makeConstraints {
            $0.top.equalTo(joinImage.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(Constants.buttonHeight)
            $0.width.equalToSuperview().multipliedBy(Constants.buttonWidthMultiplier)
        }
        
        kakaoButton.snp.makeConstraints {
            $0.top.equalTo(naverButton.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(Constants.buttonHeight)
            $0.width.equalToSuperview().multipliedBy(Constants.buttonWidthMultiplier)
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
        let socialStack = UIStackView(arrangedSubviews: [googleButton, appleButton, facebookButton])
        socialStack.axis = .horizontal
        // 최소 간격
        socialStack.spacing = 20
        socialStack.alignment = .center
        // 남는 간격
        socialStack.distribution = .equalSpacing
        view.addSubview(socialStack)
        
        socialStack.snp.makeConstraints {
            $0.top.equalTo(orLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(Constants.socialButtonSize)
        }
        
        [googleButton, appleButton, facebookButton].forEach {
            $0.snp.makeConstraints {
                $0.size.equalTo(Constants.socialButtonSize)
            }
        }
    }
    
    // MARK: - Loading State Management
    private func setLoading(_ loading: Bool) {
        isLoggingIn = loading
        
        if loading {
            loadingIndicator.startAnimating()
            view.isUserInteractionEnabled = false
        } else {
            loadingIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - Navigation
    private func navigateToNextScreen() {
        let petProfileVC = PetProfileViewController()
        navigationController?.pushViewController(petProfileVC, animated: true)
    }
    
    // MARK: - Error Handling
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
    
    // MARK: - Actions
    @objc private func kakaoLoginTapped() {
        guard !isLoggingIn else {
            return
        }

        setLoading(true)
        
        KakaoLoginManager.shared.login { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                
                switch result {
                case .success(let user):
                    let userInfo = KakaoUserInfo(from: user)
                    
                    // 사용자 정보 저장
                    UserDefaults.standard.set(true, forKey: "isKakaoLoggedIn")
                    UserDefaults.standard.set(userInfo.nickname, forKey: "userNickname")
                    UserDefaults.standard.set(userInfo.email, forKey: "userEmail")
                    
                    self?.navigateToNextScreen()
                    
                case .failure(let error):
                    if case .userCancelled = error {
                        return
                    }
                    self?.showLoginError(message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func naverLoginTapped() {
        print("Naver login tapped")
        showComingSoonAlert(for: "네이버")
    }
    
    @objc private func googleLoginTapped() {
        guard !isLoggingIn else {
            return
        }
        
        setLoading(true)
        
        guard let rootVC = self.view.window?.rootViewController else {
            setLoading(false)
            showLoginError(message: "화면 전환 컨트롤러를 찾을 수 없습니다.")
            return
        }
        
        // Google 로그인 수행
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
    @objc private func appleLoginTapped() {
        print("Apple login tapped")
        showComingSoonAlert(for: "애플")
    }
    
    @objc private func facebookLoginTapped() {
        print("Facebook login tapped")
        showComingSoonAlert(for: "페이스북")
    }
}

// MARK: - KakaoLoginManagerDelegate
extension LoginViewController: KakaoLoginManagerDelegate {
    
    func kakaoLoginDidSucceed(user: KakaoSDKUser.User) {
        let userInfo = KakaoUserInfo(from: user)
    }
    
    func kakaoLoginDidFail(error: KakaoLoginError) {
        print("카카오 로그인 실패 (Delegate): \(error.localizedDescription)")
    }
}

// MARK: - Extensions
extension LoginViewController {
    private func dismissSplashView() {
        UIView.animate(withDuration: Constants.animationDuration, animations: {
            self.splashView.alpha = 0
        }) { _ in
            self.splashView.removeFromSuperview()
        }
    }
}
