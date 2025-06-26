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
    private let subMessageLabel = UILabel()
    private let buttonStackView = UIStackView()

    private let message: String
    private let subMessage: String?
    private let buttonTitles: [String]
    private let buttonActions: [(() -> Void)?]

    private let disposeBag = DisposeBag()

    init(message: String, subMessage: String? = nil, buttonTitles: [String], buttonActions: [(() -> Void)?]) {
        self.message = message
        self.subMessage = subMessage
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

        if message.contains("항상 허용") {
            backgroundImageView.image = UIImage(named: "alertBackgroundPermission")
        } else if buttonTitles.count == 1 {
            backgroundImageView.image = UIImage(named: "alertBackgroundSingleSmall")
        } else {
            backgroundImageView.image = UIImage(named: "alertBackgroundDouble")
        }
        backgroundImageView.isUserInteractionEnabled = true
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.layer.cornerRadius = 6

        messageLabel.text = message
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.title3
        messageLabel.textColor = UIColor(named: "textPrimary")
        
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fillEqually

        for (index, title) in buttonTitles.enumerated() {
            let button = UIButton()
            button.setTitle(title, for: .normal)
            button.setTitleColor(UIColor(named: "textPrimary"), for: .normal)
            button.titleLabel?.font = UIFont.title3
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
        backgroundImageView.addSubview(messageLabel)
        backgroundImageView.addSubview(buttonStackView)
        
        if let subMessage = subMessage {
            subMessageLabel.text = subMessage
            subMessageLabel.textAlignment = .center
            subMessageLabel.numberOfLines = 0
            subMessageLabel.font = .body5
            subMessageLabel.textColor = .textPrimary
            backgroundImageView.addSubview(subMessageLabel)
            subMessageLabel.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.leading.trailing.equalToSuperview().inset(16)
                $0.bottom.equalTo(buttonStackView.snp.top).offset(-16)
            }
        }
        view.addSubview(backgroundImageView)
        
        let originHeight: CGFloat = 124
        let setHeight: CGFloat = 160
        let scale: CGFloat = setHeight / originHeight
        
        backgroundImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(276)
        }

        messageLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(24)
            
            if subMessage == nil {
                $0.bottom.equalTo(buttonStackView.snp.top).offset(-24)
            } else {
                $0.bottom.equalTo(subMessageLabel.snp.top).offset(-8)
            }
        }

        buttonStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.width.equalToSuperview()
            $0.height.equalTo(40 * scale)
        }
    }
}
