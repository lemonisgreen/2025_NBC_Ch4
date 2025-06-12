//
//  CreateLogViewController.swift
//  SherlDog
//
//  Created by 최규현 on 6/12/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - CreateLogViewController
class CreateLogViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private let titleLabel = UILabel()
    private let photoImageView = UIImageView()
    private let dateLabel = UILabel()
    private let distanceTitleLabel = UILabel()
    private let durationTitleLabel = UILabel()
    private let stepsTitleLabel = UILabel()
    private let clueTitleLabel = UILabel()
    private let distanceLabel = UILabel()
    private let durationLabel = UILabel()
    private let stepsLabel = UILabel()
    private let clueLabel = UILabel()
    private let textView = UITextView()
    private let textViewPlaceholderLabel = UILabel()
    private let textViewConstraintsLabel = UILabel()
    private let cancelButton = UIButton()
    private let shareButton = UIButton()
    private let horizontalStackView = UIStackView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        bind()
    }
}

// MARK: - Method
extension CreateLogViewController {
    
    private func bind() {
        textView.rx.text
            .subscribe(onNext: { [weak self] text in
                guard let self, let text else { return }
                
                if text.count > 150 {
                    let diff = text.count - 150
                    self.textView.text.removeLast(diff)
                }
                
                self.textViewConstraintsLabel.text = "\(text.count) / 150자"
                
                if text.count > 0 {
                    self.textViewPlaceholderLabel.isHidden = true
                } else {
                    self.textViewPlaceholderLabel.isHidden = false
                }
            })
            .disposed(by: disposeBag)
        
        self.cancelButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                // todo: 알럿 출력
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        self.shareButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                // todo: 알럿 출력
            })
            .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        view.backgroundColor = .keycolorBackground
        
        textView.addSubview(textViewPlaceholderLabel)
        
        [cancelButton, shareButton]
            .forEach { horizontalStackView.addArrangedSubview($0) }
        
        photoImageView.addSubviews([
            dateLabel,
            distanceTitleLabel,
            durationTitleLabel,
            stepsTitleLabel,
            clueTitleLabel,
            distanceLabel,
            durationLabel,
            stepsLabel,
            clueLabel
        ])
        
        view.addSubviews([
            titleLabel,
            photoImageView,
            textView,
            textViewConstraintsLabel,
            horizontalStackView
        ])
        
        titleLabel.text = "수사일지"
        titleLabel.font = .highlight3
        titleLabel.textColor = .textPrimary
        
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.backgroundColor = .black
        photoImageView.layer.cornerRadius = 6
        
        dateLabel.font = .title1
        dateLabel.textColor = .textInverse
        
        [distanceTitleLabel, durationTitleLabel, stepsTitleLabel, clueTitleLabel]
            .forEach {
                $0.font = .alert2
            }
        
        distanceTitleLabel.text = "거리"
        distanceTitleLabel.textColor = .gray50
        
        durationTitleLabel.text = "시간"
        durationTitleLabel.textColor = .textInverse
        
        stepsTitleLabel.text = "걸음수"
        stepsTitleLabel.textColor = .gray50
        
        clueTitleLabel.text = "남긴 단서"
        clueTitleLabel.textColor = .textInverse
        
        [distanceLabel, durationLabel, stepsLabel, clueLabel]
            .forEach {
                $0.font = .body1
                $0.textColor = .textInverse
                $0.text = "12332"
            }
        
        textView.font = .body5
        textView.backgroundColor = .gray50
        textView.layer.cornerRadius = 6
        textView.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        
        textViewPlaceholderLabel.text = "오늘의 수사일지를 간단히 적어주세요."
        textViewPlaceholderLabel.font = .body5
        textViewPlaceholderLabel.textColor = .textDisabled
        
        textViewConstraintsLabel.text = "0 / 150자"
        textViewConstraintsLabel.font = .alert2
        textViewConstraintsLabel.textColor = .gray400
        
        cancelButton.setTitle("취소", for: .normal)
        cancelButton.titleLabel?.font = .highlight4
        cancelButton.setTitleColor(.keycolorPrimary3, for: .normal)
        cancelButton.backgroundColor = .textInverse
        cancelButton.clipsToBounds = true
        cancelButton.layer.cornerRadius = 6
        cancelButton.layer.borderColor = UIColor.keycolorPrimary3.cgColor
        cancelButton.layer.borderWidth = 1
        
        shareButton.setTitle("공유하기", for: .normal)
        shareButton.titleLabel?.font = .highlight4
        shareButton.setTitleColor(.textInverse, for: .normal)
        shareButton.backgroundColor = .keycolorPrimary3
        shareButton.clipsToBounds = true
        shareButton.layer.cornerRadius = 6
        
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 16
        horizontalStackView.distribution = .fillEqually
    }
    
    private func configureUI() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(12)
            $0.leading.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
        
        photoImageView.snp.makeConstraints {
            $0.height.equalTo(400)
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        stepsTitleLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(22)
            $0.leading.equalToSuperview().inset(20)
        }
        
        distanceTitleLabel.snp.makeConstraints {
            $0.bottom.equalTo(stepsTitleLabel.snp.top).offset(-6)
            $0.leading.equalTo(stepsTitleLabel)
        }
        
        durationTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(127.5)
            $0.bottom.equalTo(distanceTitleLabel)
        }
        
        clueTitleLabel.snp.makeConstraints {
            $0.bottom.equalTo(stepsTitleLabel)
            $0.leading.equalTo(durationTitleLabel)
        }
        
        distanceLabel.snp.makeConstraints {
            $0.trailing.equalTo(durationTitleLabel.snp.leading).offset(-10)
            $0.centerY.equalTo(distanceTitleLabel)
        }
        
        stepsLabel.snp.makeConstraints {
            $0.trailing.equalTo(distanceLabel)
            $0.centerY.equalTo(stepsTitleLabel)
        }
        
        durationLabel.snp.makeConstraints {
            $0.leading.equalTo(durationTitleLabel.snp.trailing).offset(12)
            $0.centerY.equalTo(durationTitleLabel)
        }
        
        clueLabel.snp.makeConstraints {
            $0.leading.equalTo(clueTitleLabel.snp.trailing).offset(12)
            $0.centerY.equalTo(clueTitleLabel)
        }
        
        textView.snp.makeConstraints {
            $0.height.equalTo(180)
            $0.top.equalTo(photoImageView.snp.bottom).offset(16)
            $0.leading.trailing.equalTo(photoImageView)
        }
        
        textViewPlaceholderLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(12)
        }
        
        textViewConstraintsLabel.snp.makeConstraints {
            $0.bottom.trailing.equalTo(textView).offset(-12)
        }
        
        horizontalStackView.snp.makeConstraints {
            $0.height.equalTo(52)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
}
