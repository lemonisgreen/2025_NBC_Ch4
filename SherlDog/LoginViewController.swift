//
//  LoginViewController.swift
//  SherlDog
//
//  Created by 최영락 on 6/5/25.
//

import UIKit
import SnapKit

class LoginViewController: UIViewController {
    
    private let kakaoButton: UIButton = {
        let button = UIButton()
        button.setImage(.kakao, for: .normal)
        return button
    }()
    
    private let naverButton: UIButton = {
        let button = UIButton()
        button.setImage(.naver, for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUi()
    }
    
    func setupUi() {
        [kakaoButton, naverButton]
            .forEach { view.addSubview($0)}
        view.backgroundColor = .white
        kakaoButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(332)
            make.height.equalTo(54)
        }
        naverButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(kakaoButton.snp.bottom).offset(10)
            make.width.equalTo(332)
            make.height.equalTo(54)
        }
    }
}
