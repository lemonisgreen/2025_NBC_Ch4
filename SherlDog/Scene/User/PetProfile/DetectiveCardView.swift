//
//  DetectiveCardView.swift
//  SherlDog
//
//  Created by Jin Lee on 6/5/25.
//

import UIKit
import SnapKit

class DetectiveCardView: UIView {
    
    let detectiveHeaderBackgroundView = UIView()
    let detectiveCardLabel = UILabel()
    let detectivePhotoImageView = UIImageView()
    let detectiveNumberLabel = VerticalAlignedLabel()
    let detectiveNumber = UILabel()
    let detectiveNameLabel = VerticalAlignedLabel()
    let detectiveName = UILabel()
    let detectiveAgeLabel = VerticalAlignedLabel()
    let detectiveAge = UILabel()
    let detectiveBreedLabel = VerticalAlignedLabel()
    let detectiveBreed = UILabel()
    let detectiveIntroduceLabel = VerticalAlignedLabel()
    let detectiveIntroduceBackgroundView = UIView()
    let detectiveIntroduce = UILabel()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configurationUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {

        detectiveHeaderBackgroundView.addSubviews([detectiveCardLabel,
                                                   detectiveNumberLabel,
                                                   detectiveNumber])
        
        detectiveIntroduceBackgroundView.addSubview(detectiveIntroduce)

        self.addSubviews([
            detectiveHeaderBackgroundView,
            detectivePhotoImageView,
            detectiveNameLabel,
            detectiveName,
            detectiveBreedLabel,
            detectiveBreed,
            detectiveAgeLabel,
            detectiveAge,
            detectiveIntroduceLabel,
            detectiveIntroduceBackgroundView,
        ])
            
        self.layer.cornerRadius = 16
        self.layer.masksToBounds = true
        self.backgroundColor = .keycolorSecondary1
        
        detectiveHeaderBackgroundView.backgroundColor = .textSecondary
        
        detectiveCardLabel.text = "멍탐정 프로필 카드"
        detectiveCardLabel.font = UIFont.cardTitle
        detectiveCardLabel.textColor = .textInverse
        
        detectiveNumberLabel.text = "탐정 번호"
        detectiveNumberLabel.font = UIFont.alert2
        detectiveNumberLabel.textColor = .textInverse
        
        detectiveNumber.text = "250607" // 예시값
        detectiveNumber.font = UIFont.cardTitle
        detectiveNumber.textColor = .textInverse
        
        detectivePhotoImageView.backgroundColor = .gray300
        
        detectiveNameLabel.text = "탐정명"
        detectiveNameLabel.verticalAlignment = .top
        detectiveNameLabel.font = UIFont.alert1
        detectiveNameLabel.textColor = .textInverse
        
        detectiveName.text = "찡찡이" // 예시값
        detectiveName.font = UIFont.body4
        detectiveName.textColor = .textPrimary
        
        detectiveBreedLabel.text = "견종"
        detectiveBreedLabel.verticalAlignment = .top
        detectiveBreedLabel.font = UIFont.alert1
        detectiveBreedLabel.textColor = .textInverse

        detectiveBreed.text = "말티즈"
        detectiveBreed.font = UIFont.body4
        detectiveBreed.textColor = .textPrimary

        detectiveAgeLabel.text = "나이"
        detectiveAgeLabel.verticalAlignment = .top
        detectiveAgeLabel.font = UIFont.alert1
        detectiveAgeLabel.textColor = .textInverse

        detectiveAge.text = "3세" // 예시값
        detectiveAge.font = UIFont.body4
        detectiveAge.textColor = .textPrimary

        detectiveIntroduceLabel.text = "성격 및 특성"
        detectiveIntroduceLabel.verticalAlignment = .top
        detectiveIntroduceLabel.font = UIFont.alert1
        detectiveIntroduceLabel.textColor = .textInverse
        
        detectiveIntroduceBackgroundView.layer.cornerRadius = 24 / 2 //피그마에서는 cornerRadius값이 높이의 절반을 넘어서도 높이의 절반까지만 적용되지만 swift에서는 아님.
        detectiveIntroduceBackgroundView.layer.masksToBounds = true
        detectiveIntroduceBackgroundView.backgroundColor = .gray100

        detectiveIntroduce.text = "# 우리애기는완전쫄보"
        detectiveIntroduce.font = UIFont.title5
    }
    
    private func configurationUI() {
        
        self.snp.makeConstraints {
            $0.height.equalTo(208)
        }
        
        detectiveHeaderBackgroundView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(36)
        }
        
        detectiveCardLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().inset(16)
        }
        
        detectiveNumberLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(detectiveNumber.snp.leading).offset(-8)
        }
        
        detectiveNumber.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(13)
        }
        
        detectivePhotoImageView.snp.makeConstraints {
            $0.top.equalTo(detectiveHeaderBackgroundView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(140)
            $0.width.equalTo(100)
        }
        
        detectiveNameLabel.snp.makeConstraints {
            $0.top.equalTo(detectiveHeaderBackgroundView.snp.bottom).offset(13)
            $0.leading.equalTo(detectivePhotoImageView.snp.trailing).offset(12)
            $0.height.equalTo(20)
            $0.width.equalTo(124)
        }
        
        detectiveName.snp.makeConstraints {
            $0.top.equalTo(detectiveNameLabel.snp.bottom).offset(0)
            $0.leading.equalTo(detectivePhotoImageView.snp.trailing).offset(12)
            $0.height.equalTo(20)
            $0.width.equalTo(124)
        }
        
        detectiveAgeLabel.snp.makeConstraints {
            $0.top.equalTo(detectiveHeaderBackgroundView.snp.bottom).offset(13)
            $0.leading.equalTo(detectiveNameLabel.snp.trailing).offset(16)
            $0.height.equalTo(20)
        }
        
        detectiveAge.snp.makeConstraints {
            $0.top.equalTo(detectiveAgeLabel.snp.bottom).offset(0)
            $0.leading.equalTo(detectiveName.snp.trailing).offset(16)
            $0.height.equalTo(20)
            $0.width.equalTo(44)
        }
        
        detectiveBreedLabel.snp.makeConstraints {
            $0.top.equalTo(detectiveName.snp.bottom).offset(10)
            $0.leading.equalTo(detectivePhotoImageView.snp.trailing).offset(12)
            $0.height.equalTo(20)
        }
        
        detectiveBreed.snp.makeConstraints {
            $0.top.equalTo(detectiveBreedLabel.snp.bottom).offset(0)
            $0.leading.equalTo(detectivePhotoImageView.snp.trailing).offset(12)
            $0.height.equalTo(20)
            $0.width.equalTo(196)
        }
        
        detectiveIntroduceLabel.snp.makeConstraints {
            $0.top.equalTo(detectiveBreed.snp.bottom).offset(10)
            $0.leading.equalTo(detectivePhotoImageView.snp.trailing).offset(12)
            $0.height.equalTo(20)
        }
        
        detectiveIntroduceBackgroundView.snp.makeConstraints {
            $0.top.equalTo(detectiveIntroduceLabel.snp.bottom).offset(0)
            $0.leading.equalTo(detectivePhotoImageView.snp.trailing).offset(12)
            $0.height.equalTo(24)
        }
        
        detectiveIntroduce.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(8)
            $0.verticalEdges.equalToSuperview().inset(4)
            $0.height.equalTo(16)
        }
    }
}
