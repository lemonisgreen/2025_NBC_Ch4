//
//  RegistrationViewController.swift
//  SherlDog
//
//  Created by Jin Lee on 6/10/25.
//

import UIKit
import SnapKit

class RegistrationViewController: UIViewController {
    
    let background = EmptyFieldView()
    let registrationLabel = UILabel()
    let registImage = UIButton()
    let registNameLabel = UILabel()
    let registNameCountLabel = UILabel()
    let registNameAlertLabel = UILabel()
    let registName = UITextField()
    let registBreedLabel = UILabel()
    let registBreed = UIButton()
    let registSizeLabel = UILabel()
    let registSizeSmallButton = RegistrationSelectButton()
    let registSizeMediumButton = RegistrationSelectButton()
    let registSizeLargeButton = RegistrationSelectButton()
    let registAgeLabel = UILabel()
    let registAgeButton = UIButton()
    let registGenderLabel = UILabel()
    let registGenderFemale = RegistrationSelectButton()
    let registGenderMale = RegistrationSelectButton()
    let registNeuteredLabel = UILabel()
    let registNeuteredTrue = RegistrationSelectButton()
    let registNeuteredFalse = RegistrationSelectButton()
    let registIntroduceLabel = UILabel()
    let registIntroduce = UITextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        configureUI()
    }
    
    private func setupUI() {
    
        [
            background,
            registrationLabel,
            registImage,
            registNameLabel,
            registName,
            registNameCountLabel,
            registNameAlertLabel,
            registBreedLabel,
            registBreed,
            registSizeLabel,
            registSizeSmallButton,
            registSizeMediumButton,
            registSizeLargeButton,
            registAgeLabel,
            registAgeButton,
            registGenderLabel,
            registGenderFemale,
            registGenderMale,
            registNeuteredLabel,
            registNeuteredTrue,
            registNeuteredFalse,
            registIntroduceLabel,
            registIntroduce,
        ].forEach {
            view.addSubview($0)
        }
        
        //MARK: 배경 --
        view.backgroundColor = .gray200
        
        registrationLabel.text = "멍탐정 프로필 입력하기"
        registrationLabel.textColor = .textPrimary
        registrationLabel.font = .highlight3
        
        //MARK: 이름 --
        registNameLabel.text = "이름"
        registNameLabel.textColor = .textPrimary
        registNameLabel.font = .body1
        
        registNameCountLabel.text = "0/10"
        registNameCountLabel.textColor = .gray400
        registNameCountLabel.font = .alert2
        
        //registName
        
        registNameAlertLabel.text = "공백 없이 입력해 주세요"
        registNameAlertLabel.textColor = .textAlert
        registNameAlertLabel.font = .alert2
        
        //MARK: 견종 --
        registBreedLabel.text = "견종"
        registBreedLabel.textColor = .textPrimary
        registBreedLabel.font = .body1
        
        //registBreed
        
        //MARK: 크기 --
        registSizeLabel.text = "크기"
        registSizeLabel.textColor = .textPrimary
        registSizeLabel.font = .body1
        
//        registSizeSmallButton
//        
//        registSizeMediumButton
//        
//        registSizeLargeButton
//
        //MARK: 나이 --
        registAgeLabel.text = "나이"
        registAgeLabel.textColor = .textPrimary
        registAgeLabel.font = .body1
        
        //registAgeButton
        
        //MARK: 성별 --
        registGenderLabel.text = "성별"
        registGenderLabel.textColor = .textPrimary
        registGenderLabel.font = .body1
        
        //registGenderFemale
        
        //registGenderMale
        
        //MARK: 중성화 --
        registNeuteredLabel.text = "중성화"
        registNeuteredLabel.textColor = .textPrimary
        registNeuteredLabel.font = .body1
        
        //registNeuteredTrue
        
        //registNeuteredFalse
        
        //MARK: 성격 및 특성 --
        registIntroduceLabel.text = "성격 및 특성"
        registNeuteredLabel.textColor = .textPrimary
        registNeuteredLabel.font = .body1
        
        //registIntroduce
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
            $0.height.equalTo(44)
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
            $0.height.equalTo(44)
        }
        
        registSizeLabel.snp.makeConstraints {
            $0.top.equalTo(registImage.snp.bottom).offset(13)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registSizeSmallButton.snp.makeConstraints {
            $0.top.equalTo(registSizeLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        
        registSizeMediumButton.snp.makeConstraints {
            $0.top.equalTo(registSizeLabel.snp.bottom).offset(8)
            $0.leading.equalTo(registSizeSmallButton.snp.trailing).inset(12)
            $0.height.equalTo(48)
        }
        
        registSizeLargeButton.snp.makeConstraints {
            $0.top.equalTo(registSizeLabel.snp.bottom).offset(8)
            $0.leading.equalTo(registSizeSmallButton.snp.trailing).inset(12)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        
        registAgeLabel.snp.makeConstraints {
            $0.top.equalTo(registSizeSmallButton.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registAgeButton.snp.makeConstraints {
            $0.top.equalTo(registAgeLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registGenderLabel.snp.makeConstraints {
            $0.top.equalTo(registAgeButton.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registGenderFemale.snp.makeConstraints {
            $0.top.equalTo(registGenderLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        
        registGenderMale.snp.makeConstraints {
            $0.top.equalTo(registGenderLabel.snp.bottom).offset(8)
            $0.leading.equalTo(registGenderFemale.snp.trailing).inset(12)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
       
        registNeuteredLabel.snp.makeConstraints {
            $0.top.equalTo(registGenderFemale.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registNeuteredTrue.snp.makeConstraints {
            $0.top.equalTo(registNeuteredLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        
        registNeuteredFalse.snp.makeConstraints {
            $0.top.equalTo(registNeuteredLabel.snp.bottom).offset(8)
            $0.leading.equalTo(registNeuteredTrue.snp.trailing).inset(12)
            $0.trailing.equalToSuperview().inset(-16)
            $0.height.equalTo(48)
        }
        
        registIntroduceLabel.snp.makeConstraints {
            $0.top.equalTo(registNeuteredTrue.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registIntroduce.snp.makeConstraints {
            $0.top.equalTo(registIntroduceLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
    }
}
