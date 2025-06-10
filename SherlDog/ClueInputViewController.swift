//
//  ClueInputViewController.swift
//  SherlDog
//
//  Created by 김재우 on 6/10/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class ClueInputViewController: UIViewController {
    private let imageView = UIImageView()
    private let textView = UITextView()
    private let registerButton = UIButton()
    private let closeButton = UIButton()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindRegisterAction()
        bindCloseAction()
    }

    private func setupUI() {
        view.backgroundColor = .white

        imageView.image = UIImage(named: "")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor(named: "gray300")?.cgColor
        imageView.layer.cornerRadius = 6
        
        textView.text = ""
        textView.textColor = .textPrimary
        textView.font = UIFont(name: "Pretendard-Medium", size: 16)
        textView.layer.borderColor = UIColor(named: "gray300")?.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 6

        // Add placeholder label to textView
        let placeholderLabel = UILabel()
        placeholderLabel.text = "오늘의 수사일지를 간단히 적어주세요."
        placeholderLabel.font = UIFont(name: "Pretendard-Medium", size: 14)
        placeholderLabel.textColor = .lightGray
        placeholderLabel.textColor = UIColor.lightGray.withAlphaComponent(0.6)
        placeholderLabel.numberOfLines = 0
        textView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(10)
        }

        registerButton.setTitle("단서 등록하기", for: .normal)
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.titleLabel?.font = UIFont(name: "Pretendard-Bold", size: 18)
        registerButton.backgroundColor = UIColor(named: "keycolorPrimary2") ?? .systemGreen
        registerButton.layer.cornerRadius = 6
        
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .textPrimary
        view.addSubview(closeButton)
        
        [imageView, textView, registerButton].forEach { view.addSubview($0) }

        // Bind placeholder visibility to textView text
        textView.rx.text.orEmpty
            .map { !$0.isEmpty }
            .bind(to: placeholderLabel.rx.isHidden)
            .disposed(by: disposeBag)
    }

    private func setupConstraints() {
        imageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(32)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(imageView.snp.width).multipliedBy(1.2).priority(.low)
            $0.height.greaterThanOrEqualTo(100).priority(.low)
        }

        textView.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(120)
        }

        registerButton.snp.makeConstraints {
            $0.top.equalTo(textView.snp.bottom).offset(70)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(52)
        }
        
        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(1)
            $0.trailing.equalToSuperview().inset(16)
            $0.width.height.equalTo(24)
        }
    }

    private func bindRegisterAction() {
        registerButton.rx.tap
            .bind { [weak self] in
                print("단서 등록 로직 실행됨")
                self?.dismiss(animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindCloseAction() {
        closeButton.rx.tap
            .bind { [weak self] in
                print("dismiss")
                self?.dismiss(animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
    }
}
