//
//  CancelMembership.swift
//  SherlDog
//
//  Created by 전원식 on 6/24/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class CancelMembershipViewController : UIViewController {
    
    private let disposeBag = DisposeBag()
    let imageView = UIImageView()
    let mainLabel = UILabel()
    let contentLabel = UILabel()
    let finalLabel = UILabel()
    let cancelButton = ButtonManager(title: "취소할게요")
    let continueButton = ButtonManager(title: "그래도 탈퇴할래요")
    let buttonStackView = UIStackView()
    let separator = UIView()
    let backLabel = UILabel()
    let chevronButton = UIButton()
    let backStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        configureUI()
        bind()
        setupNavigationBar()
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
    }
    
    private func setupUI() {
        [
            imageView,
            mainLabel,
            contentLabel,
            finalLabel,
            cancelButton,
            continueButton,
            separator,
            buttonStackView
        ].forEach {
            view.addSubview($0)
        }
        
        imageView.image = UIImage(named: "cancelMembership")
        imageView.contentMode = .scaleAspectFit
        
//        mainLabel.text = "그동안 정말 많은 수사를 함께 했네요\n이건 함께 한 추억들이에요"
        mainLabel.text = "그동안 정말 많은 수사를 함께 했네요.\n함께한 시간 모두\n소중한 추억으로 남을 거예요."
        mainLabel.font = .body1
        mainLabel.textColor = .textPrimary
        mainLabel.numberOfLines = 3
        mainLabel.textAlignment = .center
        
//        contentLabel.text = "멍탐정 2마리와 12.6km를 걷고\n 1123일을 함께하며\n 114개의 단서를 남겼어요"
        contentLabel.text = "함께했던 모든 발자국과 단서들이 \n 오래도록 기억 속에 남을 거예요."
        contentLabel.font = .body6
        contentLabel.textColor = .textPrimary
        contentLabel.numberOfLines = 3
        contentLabel.textAlignment = .center
        
        finalLabel.text = "정말 탈퇴하시나요?\n멍탐정과의 모든 기록이 한순간에 사라져요"
        finalLabel.font = .body3
        finalLabel.textColor = .textPrimary
        finalLabel.numberOfLines = 0
        finalLabel.textAlignment = .center
        
        cancelButton.setBackgroundColor(UIColor(named: "textInverse")!, for: .normal)
        cancelButton.setTitleColor(UIColor(named: "keycolorPrimary3"), for: .normal)
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(named: "keycolorPrimary3")?.cgColor
        
        separator.backgroundColor = UIColor(named: "gray200")
        
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(continueButton)
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        
        backLabel.text = "회원 탈퇴"
        backLabel.font = .highlight3
        backLabel.textColor = .textPrimary

        backStack.addArrangedSubview(chevronButton)
        backStack.addArrangedSubview(backLabel)
        backStack.axis = .horizontal
        backStack.distribution = .fill
        backStack.spacing = 10
        backStack.alignment = .center

        chevronButton.setImage(UIImage(named: "leftChevron"), for: .normal)
    }
    
    private func configureUI() {
        imageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(85)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(imageView.snp.width).multipliedBy(1.3)
        }
        
        mainLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.top).offset(130)
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.equalToSuperview().inset(50)
        }
        separator.snp.makeConstraints {
            $0.top.equalTo(mainLabel.snp.bottom).offset(22)
            $0.leading.equalToSuperview().inset(52)
            $0.trailing.equalToSuperview().inset(84)
            $0.height.equalTo(1)
        }
        
        contentLabel.snp.makeConstraints {
            $0.top.equalTo(separator.snp.bottom).offset(22)
            $0.leading.equalToSuperview().inset(82)
            $0.width.equalTo(180)
        }
        
        finalLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(12)

        }
        
        buttonStackView.snp.makeConstraints {
            $0.top.equalTo(finalLabel.snp.bottom).offset(42)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(52)
        }
    }
    
    private func bind() {
        chevronButton.rx.tap
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)

        continueButton.rx.tap
            .bind { [weak self] in
                self?.showFinalConfirmationAlert()
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - 회원탈퇴 관련 메서드들
    private func showFinalConfirmationAlert() {
        let alert = AlertManager(
            message: "정말로 탈퇴하시겠습니까?",
            subMessage: "탈퇴 후에는 모든 데이터가 복구되지 않습니다",
            buttonTitles: ["아니오", "탈퇴하기"],
            buttonActions: [
                nil,
                { [weak self] in
                    self?.performDeleteAccount()
                }
            ]
        )
        present(alert, animated: true)
    }
    
    private func performDeleteAccount() {
        AccountDeletionManager.shared.deleteAccount(from: self) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.showSuccessAndNavigate()
                } else {
                    self?.showErrorAlert()
                }
            }
        }
    }
    
    private func showSuccessAndNavigate() {
        let alert = AlertManager(
            message: "회원탈퇴가 완료되었습니다",
            subMessage: "그동안 멍탐정을 이용해주셔서 감사했습니다",
            buttonTitles: ["확인"],
            buttonActions: [
                { [weak self] in
                    self?.navigateToLoginScreen()
                }
            ]
        )
        present(alert, animated: true)
    }
    
    private func showErrorAlert() {
        let alert = AlertManager(
            message: "회원탈퇴에 실패했습니다",
            subMessage: "잠시 후 다시 시도해주세요",
            buttonTitles: ["확인"],
            buttonActions: [nil]
        )
        present(alert, animated: true)
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
        let backBarButtonItem = UIBarButtonItem(customView: backStack)
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = 8
        navigationItem.leftBarButtonItems = [spacer, backBarButtonItem]
    }
}
