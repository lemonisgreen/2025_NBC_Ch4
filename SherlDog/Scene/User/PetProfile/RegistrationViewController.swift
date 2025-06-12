//
//  RegistrationViewController.swift
//  SherlDog
//
//  Created by Jin Lee on 6/10/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class RegistrationViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    let registrationLabel = UILabel()
    let registImage = UIButton()
    let registNameLabel = UILabel()
    let registNameCountLabel = UILabel()
    let registNameAlertStackView = UIStackView()
    let registNameAlertImage = UIImageView()
    let registNameAlertLabel = UILabel()
    let registName = RegistrationTextField(text: "이름을 입력하세요")
    let registBreedLabel = UILabel()
    let registBreed = RegistrationSearchButton(title: " ")
    let underLine = UIView()
    let registSizeLabel = UILabel()
    let registSizeSmallIcon = UIImageView()
    let registSizeSmallLabel = UILabel()
    let registSizeSmallStackView = UIStackView()
    let registSizeSmallButton = RegistrationSelectButton(title: nil)
    let registSizeMediumIcon = UIImageView()
    let registSizeMediumLabel = UILabel()
    let registSizeMediumStackView = UIStackView()
    let registSizeMediumButton = RegistrationSelectButton(title: nil)
    let registSizeLargeIcon = UIImageView()
    let registSizeLargeLabel = UILabel()
    let registSizeLargeStackView = UIStackView()
    let registSizeLargeButton = RegistrationSelectButton(title: nil)
    let registSizeStackButtonView = UIStackView()
    let registAgeLabel = UILabel()
    let registAgeButton = RegistrationSearchButton(title: "YYYY-MM-DD (n세)")
    let registGenderLabel = UILabel()
    let registGenderStackView = UIStackView()
    let registGenderFemale = RegistrationSelectButton(title: "여아")
    let registGenderMale = RegistrationSelectButton(title: "남아")
    let registNeuteredLabel = UILabel()
    let registNeuteredStackView = UIStackView()
    let registNeuteredTrue = RegistrationSelectButton(title: "중성화 했어요")
    let registNeuteredFalse = RegistrationSelectButton(title: "중성화 안 했어요")
    let registIntroduceLabel = UILabel()
    let registIntroduce = RegistrationTextField(text: "성격을 입력하세요")
    let registCompletButton = ButtonManager(title: "다음")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        bind()
    }
    
    func bind() {
        
        self.registName.rx.text
            .subscribe(onNext: { [weak self]  _ in
                guard let self,
                      let text = self.registName.text else { return }
                
                // 글자 공백 용납하지 않기
                let containsWhitespace = text.rangeOfCharacter(from: .whitespaces) != nil
                self.registNameAlertStackView.isHidden = !containsWhitespace
                
                self.registNameCountLabel.text = "\(text.count) / 10 자"
                
                if text.count > 10 {
                    let overText = text.count - 10
                    self.registName.text?.removeLast(overText)
                    self.registNameCountLabel.text = "10 / 10 자"
                }
            })
            .disposed(by: disposeBag)
        
        self.registSizeSmallButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registSizeSmallButton.isSelected = true
                self?.registSizeMediumButton.isSelected = false
                self?.registSizeLargeButton.isSelected = false
            })
            .disposed(by: disposeBag)
        
        self.registSizeMediumButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registSizeSmallButton.isSelected = false
                self?.registSizeMediumButton.isSelected = true
                self?.registSizeLargeButton.isSelected = false
            })
            .disposed(by: disposeBag)
        
        self.registSizeLargeButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registSizeSmallButton.isSelected = false
                self?.registSizeMediumButton.isSelected = false
                self?.registSizeLargeButton.isSelected = true
            })
            .disposed(by: disposeBag)
        
        self.registGenderFemale.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registGenderFemale.isSelected = true
                self?.registGenderMale.isSelected = false
            })
            .disposed(by: disposeBag)
        
        self.registGenderMale.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registGenderMale.isSelected = true
                self?.registGenderFemale.isSelected = false
            })
            .disposed(by: disposeBag)
        
        self.registNeuteredTrue.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registNeuteredTrue.isSelected = true
                self?.registNeuteredFalse.isSelected = false
            })
            .disposed(by: disposeBag)
        
        self.registNeuteredFalse.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registNeuteredFalse.isSelected = true
                self?.registNeuteredTrue.isSelected = false
            })
            .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        [
            registNameAlertImage,
            registNameAlertLabel
        ].forEach { registNameAlertStackView.addArrangedSubview($0) }
        
        [
            registSizeSmallIcon,
            registSizeSmallLabel
        ].forEach { registSizeSmallStackView.addArrangedSubview($0) }
        
        [
            registSizeMediumIcon,
            registSizeMediumLabel
        ].forEach { registSizeMediumStackView.addArrangedSubview($0) }
        
        [
            registSizeLargeIcon,
            registSizeLargeLabel
        ].forEach { registSizeLargeStackView.addArrangedSubview($0) }
        
        registSizeSmallButton.addSubview(registSizeSmallStackView)
        
        registSizeMediumButton.addSubview(registSizeMediumStackView)
        
        registSizeLargeButton.addSubview(registSizeLargeStackView)
        
        [
            registSizeSmallButton,
            registSizeMediumButton,
            registSizeLargeButton
        ].forEach { registSizeStackButtonView.addArrangedSubview($0) }
        
        [
            registGenderFemale,
            registGenderMale,
        ].forEach { registGenderStackView.addArrangedSubview($0) }
        
        [
            registNeuteredTrue,
            registNeuteredFalse,
        ].forEach { registNeuteredStackView.addArrangedSubview($0) }
        
        [
            registrationLabel,
            registImage,
            registNameLabel,
            registName,
            registNameCountLabel,
            registNameAlertStackView,
            registBreedLabel,
            registBreed,
            underLine,
            registSizeLabel,
            registSizeStackButtonView,
            registAgeLabel,
            registAgeButton,
            registGenderLabel,
            registGenderStackView,
            registNeuteredLabel,
            registNeuteredStackView,
            registIntroduceLabel,
            registIntroduce,
            registCompletButton,
        ].forEach { view.addSubview($0) }
        
        //MARK: 배경 --
        view.backgroundColor = .keycolorBackground
        
        registrationLabel.text = "멍탐정 프로필 입력하기"
        registrationLabel.textColor = .textPrimary
        registrationLabel.font = .highlight3
        
        //MARK: 사진 --
        
        registImage.setImage(UIImage(named: "smallPolaroid"), for: .normal)
        
        //MARK: 이름 --
        registNameLabel.text = "이름"
        registNameLabel.textColor = .textPrimary
        registNameLabel.font = .body1
        
        registNameCountLabel.text = "0 / 10 자"
        registNameCountLabel.textColor = .gray400
        registNameCountLabel.font = .alert2
        
        registNameAlertStackView.axis = .horizontal
        registNameAlertStackView.spacing = 4
        registNameAlertStackView.alignment = .leading
        
        registNameAlertImage.image = UIImage(named: "alertMark")
        registNameAlertImage.contentMode = .scaleAspectFit
        
        registNameAlertLabel.text = "공백 없이 입력해 주세요"
        registNameAlertLabel.textColor = .textAlert
        registNameAlertLabel.font = .alert2
        
        //MARK: 견종 --
        registBreedLabel.text = "견종"
        registBreedLabel.textColor = .textPrimary
        registBreedLabel.font = .body1
        
        underLine.backgroundColor = .gray200
        
        //MARK: 크기 --
        registSizeLabel.text = "크기"
        registSizeLabel.textColor = .textPrimary
        registSizeLabel.font = .body1
        
        registSizeSmallIcon.image = UIImage(named: "smallDog")
        registSizeSmallIcon.isUserInteractionEnabled = false
        registSizeSmallLabel.text = "소형견"
        registSizeSmallLabel.textColor = .textTertiary
        registSizeSmallLabel.font = .title3
        registSizeSmallLabel.isUserInteractionEnabled = false
        
        registSizeSmallStackView.backgroundColor = .clear
        registSizeSmallStackView.axis = .horizontal
        registSizeSmallStackView.spacing = 8
        registSizeSmallStackView.alignment = .center
        registSizeSmallStackView.isUserInteractionEnabled = false
        
        
        registSizeMediumIcon.image = UIImage(named: "mediumDog")
        registSizeMediumIcon.isUserInteractionEnabled = false
        registSizeMediumLabel.text = "중형견"
        registSizeMediumLabel.textColor = .textTertiary
        registSizeMediumLabel.font = .title3
        registSizeMediumLabel.isUserInteractionEnabled = false
        
        registSizeMediumStackView.backgroundColor = .clear
        registSizeMediumStackView.axis = .horizontal
        registSizeMediumStackView.spacing = 8
        registSizeMediumStackView.alignment = .center
        registSizeMediumStackView.isUserInteractionEnabled = false
        
        registSizeLargeIcon.image = UIImage(named: "largeDog")
        registSizeLargeIcon.isUserInteractionEnabled = false
        registSizeLargeLabel.text = "대형견"
        registSizeLargeLabel.textColor = .textTertiary
        registSizeLargeLabel.font = .title3
        registSizeLargeLabel.isUserInteractionEnabled = false
        
        registSizeLargeStackView.backgroundColor = .clear
        registSizeLargeStackView.axis = .horizontal
        registSizeLargeStackView.spacing = 8
        registSizeLargeStackView.alignment = .center
        registSizeLargeStackView.isUserInteractionEnabled = false
        
        registSizeStackButtonView.axis = .horizontal
        registSizeStackButtonView.spacing = 12
        registSizeStackButtonView.distribution = .fillEqually
        
        //MARK: 나이 --
        registAgeLabel.text = "나이"
        registAgeLabel.textColor = .textPrimary
        registAgeLabel.font = .body1
        
        //MARK: 성별 --
        registGenderLabel.text = "성별"
        registGenderLabel.textColor = .textPrimary
        registGenderLabel.font = .body1
        
        registGenderStackView.axis = .horizontal
        registGenderStackView.spacing = 12
        registGenderStackView.alignment = .fill
        registGenderStackView.distribution = .fillEqually
        
        //MARK: 중성화 --
        registNeuteredLabel.text = "중성화"
        registNeuteredLabel.textColor = .textPrimary
        registNeuteredLabel.font = .body1
        
        registNeuteredStackView.axis = .horizontal
        registNeuteredStackView.spacing = 12
        registNeuteredStackView.alignment = .fill
        registNeuteredStackView.distribution = .fillEqually
        
        //MARK: 성격 및 특성 --
        registIntroduceLabel.text = "성격 및 특성"
        registIntroduceLabel.textColor = .textPrimary
        registIntroduceLabel.font = .body1
    }
    
    private func configureUI() {
        
        registrationLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(34 + 16)
            $0.leading.equalToSuperview().inset(20)
        }
        
        registImage.snp.makeConstraints {
            $0.top.equalTo(registrationLabel.snp.bottom).offset(16)
            $0.leading.equalToSuperview()
            $0.height.equalTo(200)
            $0.width.equalTo(160)
        }
        
        registNameLabel.snp.makeConstraints {
            $0.top.equalTo(registrationLabel.snp.bottom).offset(16)
            $0.leading.equalTo(registImage.snp.trailing)
            $0.height.equalTo(22)
        }
        
        registName.snp.makeConstraints {
            $0.top.equalTo(registNameLabel.snp.bottom).offset(8)
            $0.leading.equalTo(registImage.snp.trailing)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        registNameAlertImage.snp.makeConstraints {
            $0.height.equalTo(17)
        }
        
        registNameCountLabel.snp.makeConstraints {
            $0.top.equalTo(registrationLabel.snp.bottom).offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(24)
        }
        
        registNameAlertStackView.snp.makeConstraints {
            $0.top.equalTo(registName.snp.bottom).offset(4)
            $0.leading.equalTo(registImage.snp.trailing)
            $0.height.equalTo(17)
            $0.width.equalTo(132)
        }
        
        registBreedLabel.snp.makeConstraints {
            $0.top.equalTo(registName.snp.bottom).offset(28)
            $0.leading.equalTo(registImage.snp.trailing)
            $0.height.equalTo(22)
        }
        
        registBreed.snp.makeConstraints {
            $0.top.equalTo(registBreedLabel.snp.bottom).offset(8)
            $0.leading.equalTo(registImage.snp.trailing)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        underLine.snp.makeConstraints {
            $0.top.equalTo(registBreed.snp.bottom).offset(24 + 4)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(1)
        }
        
        registSizeLabel.snp.makeConstraints {
            $0.top.equalTo(registImage.snp.bottom).offset(13)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registSizeSmallIcon.snp.makeConstraints {
            $0.height.width.equalTo(20)
        }
        
        registSizeSmallStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        registSizeMediumIcon.snp.makeConstraints {
            $0.height.width.equalTo(20)
        }
        
        registSizeMediumStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        registSizeLargeIcon.snp.makeConstraints {
            $0.height.width.equalTo(20)
        }
        
        registSizeLargeStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        registSizeStackButtonView.snp.makeConstraints {
            $0.top.equalTo(registSizeLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        registAgeLabel.snp.makeConstraints {
            $0.top.equalTo(registSizeSmallButton.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registAgeButton.snp.makeConstraints {
            $0.top.equalTo(registAgeLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        registGenderLabel.snp.makeConstraints {
            $0.top.equalTo(registAgeButton.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registGenderStackView.snp.makeConstraints {
            $0.top.equalTo(registGenderLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        registNeuteredLabel.snp.makeConstraints {
            $0.top.equalTo(registGenderFemale.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registNeuteredStackView.snp.makeConstraints {
            $0.top.equalTo(registNeuteredLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        registIntroduceLabel.snp.makeConstraints {
            $0.top.equalTo(registNeuteredTrue.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registIntroduce.snp.makeConstraints {
            $0.top.equalTo(registIntroduceLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        registCompletButton.snp.makeConstraints {
            $0.top.equalTo(registIntroduce.snp.bottom).offset(12 + 16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
}
