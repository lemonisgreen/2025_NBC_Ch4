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
        
        mainLabel.text = "그동안 정말 많은 수사를 함께 했네요\n이건 함께 한 추억들이에요"
        mainLabel.font = .body1
        mainLabel.textColor = .textPrimary
        mainLabel.numberOfLines = 2
        mainLabel.textAlignment = .center
        
        contentLabel.text = "멍탐정 2마리와 12.6km를 걷고\n 1123일을 함께하며\n 114개의 단서를 남겼어요"
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
    }
    
    private func setupNavigationBar() {
        let backBarButtonItem = UIBarButtonItem(customView: backStack)
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = 8
        navigationItem.leftBarButtonItems = [spacer, backBarButtonItem]
    }
}
