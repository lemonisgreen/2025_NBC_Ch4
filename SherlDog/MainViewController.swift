//
//  MainViewController.swift
//  SherlDog
//
//  Created by 전원식 on 6/9/25.
//

import UIKit
import SnapKit

class MainViewController : UIViewController {
    
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
        walkStartButton.setTitleColor(.white, for: .normal)
        walkStartButton.backgroundColor = UIColor(red: 82/255.0, green: 173/255.0, blue: 80/255.0, alpha: 1.0)
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

