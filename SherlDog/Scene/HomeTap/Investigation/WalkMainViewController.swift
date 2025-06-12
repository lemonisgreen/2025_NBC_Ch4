//
//  WalkMainViewController.swift
//  SherlDog
//
//  Created by 전원식 on 6/9/25.

//

import UIKit
import SnapKit
import NMapsMap

class WalkMainViewController : UIViewController {
    
    private let walkStartButton = UIButton()
    
    private let mapView = NMFMapView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        configureUI()
        walkStartButton.addTarget(self, action: #selector(walkStartButtonTapped), for: .touchUpInside)
    }
    
    private func setupUI() {
        [
            mapView,
            walkStartButton
        ].forEach {
            view.addSubview($0)
        }
        mapView.positionMode = .normal
        
        walkStartButton.setTitle("수사 시작하기", for: .normal)
        walkStartButton.setTitleColor(UIColor(named: "textInverse"), for: .normal)
        walkStartButton.titleLabel?.font = UIFont.highlight4
        walkStartButton.backgroundColor = UIColor(named: "keycolorPrimary3")
        walkStartButton.layer.cornerRadius = 6
    }
    
    private func configureUI() {
        mapView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        walkStartButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(100)
            $0.height.equalTo(52)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
    @objc private func walkStartButtonTapped() {
        let modalVC = WalkEndModalViewController()
        modalVC.modalPresentationStyle = .overFullScreen
        present(modalVC, animated: true)
    }
}

