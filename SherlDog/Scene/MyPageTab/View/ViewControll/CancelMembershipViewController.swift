//
//  WithdrawViewController.swift
//  SherlDog
//
//  Created by 전원식 on 6/24/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class WithdrawViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components (기존과 동일)
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    let imageView = UIImageView()
    let mainLabel = UILabel()
    let contentLabel = UILabel()
    let finalLabel = UILabel()
    let cancelButton = ButtonFactory.makeButton(type: .sub, title: "취소할게요")
    let continueButton = ButtonFactory.makeButton(type: .main, title: "그래도 탈퇴할래요")
    let buttonStackView = UIStackView()
    let separator = UIView()
    let backLabel = UILabel()
    let chevronButton = UIButton()
    let backStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .keycolorTertiaryBG
        setupUI()
        configureUI()
        bind()
        setupNavigationBar()
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
    }
    
    private func setupUI() {
        // ScrollView 추가 (작은 화면 대응)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
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
            contentView.addSubview($0)
        }
        
        imageView.image = UIImage(named: "withdrawFile")
        imageView.contentMode = .scaleAspectFit
        
        mainLabel.text = "그동안 정말 많은 수사를 함께 했네요.\n함께한 시간 모두\n소중한 추억으로 남을 거예요."
        mainLabel.font = .body1
        mainLabel.textColor = .textPrimary
        mainLabel.numberOfLines = 3
        mainLabel.textAlignment = .center
        
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
        setupScrollView()
        setupConstraints()
    }
    
    private func setupScrollView() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
    }
    
    private func setupConstraints() {
        // 이미지뷰 - Safe Area 기반으로 개선
        imageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            
            // 화면 크기에 따라 적응적으로 높이 조정
            $0.height.equalTo(imageView.snp.width).multipliedBy(1.3).priority(.medium)
            $0.height.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.height).multipliedBy(0.6).priority(.high)
        }
        
        // 메인 라벨 - 이미지 위에 오버레이 (원래 위치)
        mainLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.top).offset(130) // 원래 위치로 복원
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.equalToSuperview().inset(50)
        }
        
        // 구분선 - 원래 위치로 복원
        separator.snp.makeConstraints {
            $0.top.equalTo(mainLabel.snp.bottom).offset(22)
            $0.leading.equalToSuperview().inset(52)
            $0.trailing.equalToSuperview().inset(84)
            $0.height.equalTo(1)
        }
        
        // 컨텐츠 라벨 - 원래 위치로 복원
        contentLabel.snp.makeConstraints {
            $0.top.equalTo(separator.snp.bottom).offset(22)
            $0.leading.equalToSuperview().inset(82)
            $0.width.equalTo(180)
        }
        
        // 최종 라벨 - 이미지 하단에 배치
        finalLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        
        // 버튼 스택뷰
        buttonStackView.snp.makeConstraints {
            $0.top.equalTo(finalLabel.snp.bottom).offset(42)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(52)
            $0.bottom.equalToSuperview().inset(20) // ScrollView 하단 여백
        }
        
        // ContentView 최소 높이 보장
        contentView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.height).priority(.low)
        }
    }
    
    private func bind() {
        chevronButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)

        continueButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.showFinalConfirmationAlert()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - 회원탈퇴 관련 메서드들
    private func showFinalConfirmationAlert() {
        let alert = CustomAlertViewController(
            message: "정말로 탈퇴하시겠습니까?",
            subMessage: "탈퇴 후에는 모든 데이터가 복구되지 않습니다",
            buttons: [
                CustomAlertViewController.AlertButton(
                    title: "아니오",
                    action: nil
                ),
                CustomAlertViewController.AlertButton(
                    title: "탈퇴하기",
                    action: { [weak self] in
                        self?.performDeleteAccount()
                    }
                )
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
        let alert = CustomAlertViewController(
            message: "회원탈퇴가 완료되었습니다",
            subMessage: "그동안 멍탐정을 이용해주셔서 감사했습니다",
            buttons: [
                CustomAlertViewController.AlertButton(
                    title: "확인",
                    action: { [weak self] in
                        self?.navigateToLoginScreen()
                    }
                )
            ]
        )
        present(alert, animated: true)
    }
    
    private func showErrorAlert() {
        let alert = CustomAlertViewController(
            message: "회원탈퇴에 실패했습니다",
            subMessage: "잠시 후 다시 시도해주세요",
            buttons: [
                CustomAlertViewController.AlertButton(
                    title: "확인",
                    action: nil
                )
            ]
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
