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

class CustomAlertViewController: UIViewController {

    private let backgroundView = UIView()
    private let messageLabel = UILabel()
    private let subMessageLabel = UILabel()
    private let buttonStackView = UIStackView()

    private let message: String
    private let subMessage: String?
    private let buttons: [AlertButton]
    
    private let horizontalLine = UIView()
    private let verticalLine = UIView()

    private let disposeBag = DisposeBag()
    
    struct AlertButton {
        let title: String
        let action: (() -> Void)?
    }

    init(message: String, subMessage: String? = nil, buttons: [AlertButton]) {
        self.message = message
        self.subMessage = subMessage
        self.buttons = buttons
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
            horizontalLine.isHidden = false
            verticalLine.isHidden = false
        } else if buttons.count == 1 {
            horizontalLine.isHidden = false
            verticalLine.isHidden = true
        } else {
            horizontalLine.isHidden = false
            verticalLine.isHidden = false
        }
        backgroundView.isUserInteractionEnabled = true
        backgroundView.backgroundColor = .white
        backgroundView.layer.cornerRadius = 12
        backgroundView.clipsToBounds = true

        messageLabel.text = message
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.title3
        messageLabel.textColor = UIColor(named: "textPrimary")
        
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fillEqually

        for (index, buttonData) in buttons.enumerated() {
            let button = UIButton()
            button.setTitle(buttonData.title, for: .normal)
            button.setTitleColor(UIColor(named: "textPrimary"), for: .normal)
            button.titleLabel?.font = UIFont.title3
            button.tag = index

            button.rx.tap
                .bind { [weak self] in
                    guard let self else { return }
                    self.dismiss(animated: true) {
                        buttonData.action?()
                    }
                }
                .disposed(by: disposeBag)

            buttonStackView.addArrangedSubview(button)
        }
        backgroundView.addSubview(messageLabel)
        backgroundView.addSubview(buttonStackView)
        
        if let subMessage = subMessage {
            subMessageLabel.text = subMessage
            subMessageLabel.textAlignment = .center
            subMessageLabel.numberOfLines = 0
            subMessageLabel.font = .body5
            subMessageLabel.textColor = .textPrimary
            backgroundView.addSubview(subMessageLabel)
            subMessageLabel.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.leading.trailing.equalToSuperview().inset(16)
                $0.bottom.equalTo(buttonStackView.snp.top).offset(-16)
            }
        }
        view.addSubview(backgroundView)
        
        let originHeight: CGFloat = 124
        let setHeight: CGFloat = 160
        let scale: CGFloat = setHeight / originHeight
        
        backgroundView.snp.makeConstraints {
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
        
        horizontalLine.backgroundColor = UIColor(named: "gray200")
        backgroundView.addSubview(horizontalLine)
        
        horizontalLine.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
            $0.bottom.equalTo(buttonStackView.snp.top)
        }
        
        verticalLine.backgroundColor = UIColor(named: "gray200")
        backgroundView.addSubview(verticalLine)
        
        verticalLine.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(buttonStackView.snp.top)
            $0.bottom.equalTo(buttonStackView.snp.bottom)
            $0.width.equalTo(1)
        }
    }
}
