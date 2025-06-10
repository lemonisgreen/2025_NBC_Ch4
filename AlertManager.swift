//
//  AlertManager.swift
//  SherlDog
//
//  Created by 전원식 on 6/10/25.
//
import UIKit
import SnapKit

class AlertManager: UIViewController {

    private let backgroundImageView = UIImageView()
    private let messageLabel = UILabel()
    private let closeButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        backgroundImageView.image = UIImage(named: "alert_background")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.layer.cornerRadius = 6

        messageLabel.text = "등록되었습니다."
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "Pretendard-Medium", size: 18)
        messageLabel.textColor = .black

        closeButton.setTitle("닫기", for: .normal)
        closeButton.backgroundColor = .white
        closeButton.setTitleColor(UIColor.black, for: .normal)
        closeButton.titleLabel?.font = UIFont(name: "Pretendard-Medium", size: 18)
        closeButton.layer.cornerRadius = 6
        closeButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        [backgroundImageView, messageLabel, closeButton].forEach { view.addSubview($0) }

        backgroundImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(276)
            $0.height.equalTo(124)
        }
        
        messageLabel.snp.makeConstraints {
            $0.centerX.equalTo(backgroundImageView)
            $0.top.equalTo(backgroundImageView.snp.top).offset(30)
        }

        closeButton.snp.makeConstraints {
            $0.centerX.equalTo(backgroundImageView)
            $0.bottom.equalTo(backgroundImageView.snp.bottom).inset(20)
            $0.width.equalTo(244)
            $0.height.equalTo(18)
        }
    }

    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}
