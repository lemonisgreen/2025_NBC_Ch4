//
//  RegistrationViewController.swift
//  SherlDog
//
//  Created by Jin Lee on 6/10/25.
//

import UIKit
import SnapKit

class RegistrationViewController: UIViewController {
    
    let registrationLabel = UILabel()
    let registImage = UIButton()
    let registNameLabel = UILabel()
    let registNameCountLabel = UILabel()
    let registNameAlertLabel = UILabel()
    let registName = RegistrationTextField(text: "이름을 입력하세요")
    let registBreedLabel = UILabel()
    let registBreed = RegistrationSearchButton(title: " ")
    let registSizeLabel = UILabel()
    let registSizeStackView = UIStackView()
    let registSizeSmallButton = RegistrationSelectButton(title: "소형견")
    let registSizeMediumButton = RegistrationSelectButton(title: "중형견")
    let registSizeLargeButton = RegistrationSelectButton(title: "대형견")
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
    }
    
    private func setupUI() {
        
        [
            registSizeSmallButton,
            registSizeMediumButton,
            registSizeLargeButton
        ]
            .forEach {
                registSizeStackView.addArrangedSubview($0)
            }
        [
            registGenderFemale,
            registGenderMale,
        ]
            .forEach {
                registGenderStackView.addArrangedSubview($0)
            }
        [
            registNeuteredTrue,
            registNeuteredFalse,
        ]
            .forEach {
                registNeuteredStackView.addArrangedSubview($0)
            }
        
        [
            registrationLabel,
            registImage,
            registNameLabel,
            registName,
            registNameCountLabel,
            registNameAlertLabel,
            registBreedLabel,
            registBreed,
            registSizeLabel,
            registSizeStackView,
            registAgeLabel,
            registAgeButton,
            registGenderLabel,
            registGenderStackView,
            registNeuteredLabel,
            registNeuteredStackView,
            registIntroduceLabel,
            registIntroduce,
        ].forEach {
            view.addSubview($0)
        }
        
        //MARK: 배경 --
        view.backgroundColor = .keycolorBackground
        
        registrationLabel.text = "멍탐정 프로필 입력하기"
        registrationLabel.textColor = .textPrimary
        registrationLabel.font = .highlight3
        
        //MARK: 사진 --

        
        //MARK: 이름 --
        registNameLabel.text = "이름"
        registNameLabel.textColor = .textPrimary
        registNameLabel.font = .body1
        
        registNameCountLabel.text = "0/10"
        registNameCountLabel.textColor = .gray400
        registNameCountLabel.font = .alert2
        
        registNameAlertLabel.text = "공백 없이 입력해 주세요"
        registNameAlertLabel.textColor = .textAlert
        registNameAlertLabel.font = .alert2
        
        //MARK: 견종 --
        registBreedLabel.text = "견종"
        registBreedLabel.textColor = .textPrimary
        registBreedLabel.font = .body1
                
        //MARK: 크기 --
        registSizeLabel.text = "크기"
        registSizeLabel.textColor = .textPrimary
        registSizeLabel.font = .body1
        
        registSizeStackView.axis = .horizontal
        registSizeStackView.spacing = 12
        registSizeStackView.alignment = .fill
        registSizeStackView.distribution = .fillEqually
   
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
        registNeuteredLabel.textColor = .textPrimary
        registNeuteredLabel.font = .body1
        
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
        
        registNameCountLabel.snp.makeConstraints {
            $0.top.equalTo(registrationLabel.snp.bottom).offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registNameAlertLabel.snp.makeConstraints {
            $0.top.equalTo(registName.snp.bottom).offset(4)
            $0.leading.equalTo(registImage.snp.trailing)
            $0.height.equalTo(17)
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
        
        registSizeLabel.snp.makeConstraints {
            $0.top.equalTo(registImage.snp.bottom).offset(13)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registSizeStackView.snp.makeConstraints {
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
    }
}
