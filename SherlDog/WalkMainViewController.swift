//
//  WalkMainViewController.swift
//  SherlDog
//
//  Created by 전원식 on 6/9/25.

//

import UIKit
import SnapKit

class WalkMainViewController : UIViewController {
    
    private let walkStartButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        configureUI()
        walkStartButton.addTarget(self, action: #selector(walkStartButtonTapped), for: .touchUpInside)
    }
    
    private func setupUI() {
        
        [
            walkStartButton
        ].forEach {
            view.addSubview($0)
        }
        
        walkStartButton.setTitle("수사 시작하기", for: .normal)
        walkStartButton.setTitleColor(UIColor(named: "textInverse"), for: .normal)
        walkStartButton.titleLabel?.font = UIFont.highlight4
        walkStartButton.backgroundColor = UIColor(named: "keycolorPrimary3")
        walkStartButton.layer.cornerRadius = 6
    }
    
    private func configureUI() {
        
        walkStartButton.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
            $0.height.equalTo(52)
            $0.width.equalTo(343)
        }
    }
    
    @objc private func walkStartButtonTapped() {
        let modalVC = WalkEndModalViewController()
        present(modalVC, animated: true)
    }
    
}

