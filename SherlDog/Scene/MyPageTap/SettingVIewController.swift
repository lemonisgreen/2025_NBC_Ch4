//
//  Setting.swift
//  SherlDog
//
//  Created by 전원식 on 6/24/25.
//

import UIKit
import SnapKit

class SettingVIewController : UIViewController {
    
    let loginView = UIView()
    let loginStack = UIStackView()
    let loginLabel = UILabel()
    let loginButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupUI()
        configureUI()
//        bind()
    }
    
    private func setupUI() {
        [
            loginView,
            loginStack,
            loginLabel,
            loginButton
        ].forEach {
            view.addSubview($0)
        }
        
        loginView.backgroundColor = .keycolorPrimary2
        loginView.layer.cornerRadius = 12
        loginView.layer.masksToBounds = true
        
        loginLabel.font = .body1
        loginLabel.textColor = .keycolorPrimary2
        loginLabel.backgroundColor = .clear
        
        loginButton.setTitle("로그아웃", for: .normal)
        loginButton.backgroundColor = .clear
        loginButton.setTitleColor(.keycolorPrimary2, for: .normal)
        
        
        loginStack.axis = .horizontal
        loginStack.spacing = 160
        loginStack.alignment = .leading
        loginStack.addArrangedSubview(loginLabel)
        loginStack.addArrangedSubview(loginButton)
    }
    
    private func configureUI() {
        
        loginView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(82)
            $0.centerX.equalToSuperview()
        }
    }
}
