//
//  Setting.swift
//  SherlDog
//
//  Created by 전원식 on 6/24/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class SettingViewController : UIViewController {
    
    private let disposeBag = DisposeBag()
    let loginView = UIView()
    let loginStack = UIStackView()
    let loginLabel = UILabel()
    let loginButton = UIButton()
    let clauseStack = UIStackView()
    let clauseLabel = UILabel()
    let clauseButton = UIButton()
    let privacyPolicyStack = UIStackView()
    let privacyPolicyLabel = UILabel()
    let privacyPolicyButton = UIButton()
    let cancelMembershipStack = UIStackView()
    let cancelMembershipLabel = UILabel()
    let cancelmembershipButton = UIButton()
    let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    let settingBackStack = UIStackView()
    let settingBackButton = UIButton()
    let settingTitleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .keycolorInverse
        setupUI()
        configureUI()
        bind()
        setupNavigationBar()
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        updateLoginStatus()
    }
    
    private func setupUI() {
        [
            loginView,
            loginStack,
            loginLabel,
            loginButton,
            clauseStack,
            clauseLabel,
            clauseButton,
            privacyPolicyStack,
            privacyPolicyLabel,
            privacyPolicyButton,
            cancelMembershipStack,
            cancelMembershipLabel,
            cancelmembershipButton,
        ].forEach {
            view.addSubview($0)
        }
        
        loginView.addSubview(loginStack)
        loginView.backgroundColor = .keycolorPrimary5
        loginView.layer.cornerRadius = 12
        loginView.layer.masksToBounds = true
        
        loginLabel.text = "카카오 로그인"
        loginLabel.font = .body1
        loginLabel.textColor = .keycolorPrimary2
        loginLabel.backgroundColor = .clear
        
        loginButton.setTitle("로그아웃", for: .normal)
        loginButton.backgroundColor = .keycolorPrimary5
        loginButton.setTitleColor(.keycolorPrimary2, for: .normal)
        loginButton.titleLabel?.font = .body1
        
        loginStack.axis = .horizontal
        loginStack.spacing = 50
        loginStack.alignment = .center
        loginStack.addArrangedSubview(loginLabel)
        loginStack.addArrangedSubview(loginButton)
        
        clauseLabel.text = "이용약관"
        clauseLabel.font = .body1
        clauseLabel.textColor = .textPrimary
        
        clauseButton.setImage(UIImage(named: "rightChevron"), for: .normal)
        
        clauseStack.axis = .horizontal
        clauseStack.spacing = 50
        clauseStack.alignment = .leading
        clauseStack.addArrangedSubview(clauseLabel)
        clauseStack.addArrangedSubview(clauseButton)
        
        privacyPolicyLabel.text = "개인정보 처리방침"
        privacyPolicyLabel.font = .body1
        privacyPolicyLabel.textColor = .textPrimary
        
        privacyPolicyButton.setImage(UIImage(named: "rightChevron"), for: .normal)
        
        privacyPolicyStack.axis = .horizontal
        privacyPolicyStack.spacing = 50
        privacyPolicyStack.alignment = .leading
        privacyPolicyStack.addArrangedSubview(privacyPolicyLabel)
        privacyPolicyStack.addArrangedSubview(privacyPolicyButton)
        
        cancelMembershipLabel.text = "회원탈퇴"
        cancelMembershipLabel.font = .body1
        cancelMembershipLabel.textColor = .textPrimary
        cancelmembershipButton.setImage(UIImage(named: "rightChevron"), for: .normal)
        
        cancelMembershipStack.axis = .horizontal
        cancelMembershipStack.spacing = 50
        cancelMembershipStack.alignment = .leading
        cancelMembershipStack.addArrangedSubview(cancelMembershipLabel)
        cancelMembershipStack.addArrangedSubview(cancelmembershipButton)
        
        spacer.width = -8
        
        settingBackButton.setImage(UIImage(named: "leftChevron"), for: .normal)
        settingTitleLabel.text = "설정"
        settingTitleLabel.font = .highlight3
        settingTitleLabel.textColor = .textPrimary
        
        settingBackStack.addArrangedSubview(settingBackButton)
        settingBackStack.addArrangedSubview(settingTitleLabel)
        settingBackStack.axis = .horizontal
        settingBackStack.spacing = 10
        settingBackStack.alignment = .center
        
    }
    
    private func configureUI() {
        loginView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(120)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(62)
        }
        
        loginStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
        
        clauseStack.snp.makeConstraints {
            $0.top.equalTo(loginStack.snp.bottom).offset(61)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        privacyPolicyStack.snp.makeConstraints {
            $0.top.equalTo(clauseStack.snp.bottom).offset(34)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        cancelMembershipStack.snp.makeConstraints {
            $0.top.equalTo(privacyPolicyStack.snp.bottom).offset(34)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
    private func updateLoginStatus() {
        if UserDefaults.standard.bool(forKey: "isKakaoLoggedIn") {
            loginLabel.text = "카카오 로그인"
        } else if UserDefaults.standard.bool(forKey: "isGoogleLoggedIn") {
            loginLabel.text = "구글 로그인"
        } else if UserDefaults.standard.bool(forKey: "isAppleLoggedIn") {
            loginLabel.text = "Apple 로그인"
        } else {
            loginLabel.text = "로그인되지 않음"
            return
        }
        loginButton.setTitle("로그아웃", for: .normal)
    }
    
    private func bind() {
        // 로그아웃 버튼 추가
        loginButton.rx.tap
            .bind { [weak self] in
                self?.showLogoutAlert()
            }
            .disposed(by: disposeBag)
        
        cancelmembershipButton.rx.tap
            .bind { [weak self] in
                let cancelMembershipVC = CancelMembershipViewController()
                self?.navigationController?.pushViewController(cancelMembershipVC, animated: true)
            }
            .disposed(by: disposeBag)
        
        settingBackButton.rx.tap
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - 로그아웃 관련 메서드들
    private func showLogoutAlert() {
        let alert = AlertManager(
            message: "정말 로그아웃 하시겠습니까?",
            subMessage: nil,
            buttonTitles: ["취소", "로그아웃"],
            buttonActions: [
                nil, // 취소 버튼 - 아무것도 안함
                { [weak self] in // 로그아웃 버튼
                    self?.performLogout()
                }
            ]
        )
        present(alert, animated: true)
    }

    private func performLogout() {
        
        AuthManager.shared.logout { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.showLogoutSuccessAndNavigate()
                } else {
                    self?.showLogoutErrorAlert()
                }
            }
        }
    }

    private func showLogoutSuccessAndNavigate() {
        // 성공 알럿 표시 후 로그인 화면으로 이동
        let successAlert = AlertManager(
            message: "로그아웃되었습니다",
            subMessage: nil,
            buttonTitles: ["확인"],
            buttonActions: [
                { [weak self] in
                    self?.navigateToLoginScreen()
                }
            ]
        )
        present(successAlert, animated: true)
    }

    private func showLogoutErrorAlert() {
        let errorAlert = AlertManager(
            message: "로그아웃에 실패했습니다",
            subMessage: "다시 시도해주세요",
            buttonTitles: ["확인"],
            buttonActions: [nil]
        )
        present(errorAlert, animated: true)
    }

    private func navigateToLoginScreen() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else { return }
        
        let loginVC = LoginViewController()
        let navigationController = UINavigationController(rootViewController: loginVC)
        
        UIView.transition(with: sceneDelegate.window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
            sceneDelegate.window?.rootViewController = navigationController
        })
    }
    
    private func setupNavigationBar() {
        let barItem = UIBarButtonItem(customView: settingBackStack)
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = 8
        navigationItem.leftBarButtonItems = [spacer, barItem]
    }

}
