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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .keycolorInverse
        setupUI()
        configureUI()
        bind()
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
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
            cancelmembershipButton
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
    
    private func bind() {
        cancelmembershipButton.rx.tap
            .bind { [weak self] in
                let cancelMembershipVC = CancelMembershipViewController()
                self?.navigationController?.navigationBar.titleTextAttributes = [
                    .foregroundColor: UIColor(named: "textPrimary"),
                    .font: UIFont.highlight3
                ]
                self?.navigationController?.navigationBar.tintColor = .textPrimary
                self?.navigationController?.pushViewController(cancelMembershipVC, animated: true)
            }
            .disposed(by: disposeBag)
            }
    }
