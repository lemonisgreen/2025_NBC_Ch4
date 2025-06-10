//
//  LoginViewController.swift
//  SherlDog
//
//  Created by 최영락 on 6/5/25.
//

import UIKit
import SnapKit

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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupSplashView()
        navigationItem.backButtonTitle = ""
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "F0EFE9")
        
        [logo, helloLabel, helloLabel2, joinImage, orLabel,
         naverButton, kakaoButton, googleButton, appleButton, facebookButton]
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
    
    // MARK: - Actions
    @objc private func kakaoLoginTapped() {
        print("Kakao login tapped")
        navigationController?.pushViewController(PetProfileViewController(), animated: true)
    }
    
    @objc private func naverLoginTapped() {
        print("Naver login tapped")
        navigationController?.pushViewController(PetProfileViewController(), animated: true)
    }
    
    @objc private func googleLoginTapped() {
        print("Google login tapped")
        navigationController?.pushViewController(PetProfileViewController(), animated: true)
    }
    
    @objc private func appleLoginTapped() {
        print("Apple login tapped")
    }
    
    @objc private func facebookLoginTapped() {
        print("Facebook login tapped")
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
