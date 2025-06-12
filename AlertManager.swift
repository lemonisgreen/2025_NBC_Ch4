//
//  AlertManager.swift
//  SherlDog
//
//  Created by 전원식 on 6/10/25.
//
import UIKit
import SnapKit
import RxSwift
import RxCocoa

class AlertManager: UIViewController {

    private let backgroundImageView = UIImageView()
    private let messageLabel = UILabel()
    private let buttonStackView = UIStackView()

    private let message: String
    private let buttonTitles: [String]
    private let buttonActions: [(() -> Void)?]

    private let disposeBag = DisposeBag()

    init(message: String, buttonTitles: [String], buttonActions: [(() -> Void)?]) {
        self.message = message
        self.buttonTitles = buttonTitles
        self.buttonActions = buttonActions
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        if buttonTitles.count == 1 {
            backgroundImageView.image = UIImage(named: "alert_background_single")
        } else {
            backgroundImageView.image = UIImage(named: "alert_background_double")
        }
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.layer.cornerRadius = 6

        messageLabel.text = message
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.title3
        messageLabel.textColor = .black

        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fillEqually

        for (index, title) in buttonTitles.enumerated() {
            let button = UIButton()
            button.setTitle(title, for: .normal)
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
            button.titleLabel?.font = UIFont.title3
            button.layer.cornerRadius = 6
            button.tag = index

            button.rx.tap
                .bind { [weak self] in
                    guard let self else { return }
                    self.dismiss(animated: true) {
                        let action = self.buttonActions[button.tag]
                        action?()
                    }
                }
                .disposed(by: disposeBag)

            buttonStackView.addArrangedSubview(button)
        }

        [backgroundImageView, messageLabel, buttonStackView].forEach { view.addSubview($0) }

        backgroundImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(276)
            $0.height.equalTo(160)
        }

        messageLabel.snp.makeConstraints {
            $0.centerX.equalTo(backgroundImageView)
            $0.centerY.equalTo(backgroundImageView.snp.centerY).offset(-25)
        }

        buttonStackView.snp.makeConstraints {
            $0.centerX.equalTo(backgroundImageView)
            $0.bottom.equalTo(backgroundImageView.snp.bottom).inset(15)
            $0.width.equalTo(244)
            $0.height.equalTo(40)
        }
    }
}
