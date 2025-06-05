//
//  WalkEndModalViewController.swift
//  SherlDog
//
//  Created by 전원식 on 6/9/25.
//

import UIKit

class WalkEndModalViewController : UIViewController {
    
    let todayLabel = UILabel()
    let distanceLabel = UILabel()
    let timeLabel = UILabel()
    let stepCountLabel = UILabel()
    let distanceContentLabel = UILabel()
    let timeContentLabel = UILabel()
    let stepCountContentLabel = UILabel()
    let dogImage = UIImageView()
    let walkEndLabel = UILabel()
    let walkShareButton = UIButton()
    
    let infoStack = UIStackView()
    let timeStack = UIStackView()
    let distanceStack = UIStackView()
    let stepCountStack = UIStackView()
    
    let topSeperatorLine = UIView()
    let middleSeperatorLine = UIView()
    let bottomSeperatorLine = UIView()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        configureUI()
        
    }
    
    private func setupUI() {
        
        [
            todayLabel,
            distanceLabel,
            timeLabel,
            stepCountLabel,
            distanceContentLabel,
            timeContentLabel,
            stepCountContentLabel,
            dogImage,
            walkEndLabel,
            walkShareButton,
            infoStack,
            timeStack,
            distanceStack,
            stepCountStack,
            topSeperatorLine,
            middleSeperatorLine,
            bottomSeperatorLine
        ].forEach {
            view.addSubview($0)
        }
        
        todayLabel.text = "2025.06.05"
        todayLabel.textColor = .black
        todayLabel.font = UIFont.systemFont(ofSize: 20)
        todayLabel.textAlignment = .left
        
        distanceLabel.text = "거리(km)"
        distanceLabel.textColor = .black
        distanceLabel.font = UIFont.systemFont(ofSize: 14)
        
        timeLabel.text = "시간"
        timeLabel.textColor = .black
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        
        stepCountLabel.text = "걸음수"
        stepCountLabel.textColor = .black
        stepCountLabel.font = UIFont.systemFont(ofSize: 14)
        
        distanceContentLabel.text = "11.23"
        distanceContentLabel.textColor = .black
        distanceContentLabel.font = UIFont.systemFont(ofSize: 24)
        
        timeContentLabel.text = "10:11:12"
        timeContentLabel.textColor = .black
        timeContentLabel.font = UIFont.systemFont(ofSize: 24)
        
        stepCountContentLabel.text = "12345"
        stepCountContentLabel.textColor = .black
        stepCountContentLabel.font = UIFont.systemFont(ofSize: 24)
        
        dogImage.image = UIImage(systemName: "pawprint.fill")
        
        walkEndLabel.text = "멍탐정들과 함께 수사 완료!"
        walkEndLabel.textColor = .black
        
        walkShareButton.setTitle("수사 일지 공유하기", for: .normal)
        walkShareButton.backgroundColor = UIColor(red: 82/255.0, green: 173/255.0, blue: 80/255.0, alpha: 1.0)
        walkShareButton.layer.cornerRadius = 6
        
        distanceStack.axis = .vertical
        distanceStack.alignment = .center
        distanceStack.addArrangedSubview(distanceLabel)
        distanceStack.addArrangedSubview(distanceContentLabel)
        
        timeStack.axis = .vertical
        timeStack.alignment = .center
        timeStack.addArrangedSubview(timeLabel)
        timeStack.addArrangedSubview(timeContentLabel)
        
        stepCountStack.axis = .vertical
        stepCountStack.alignment = .center
        stepCountStack.addArrangedSubview(stepCountLabel)
        stepCountStack.addArrangedSubview(stepCountContentLabel)
        
        infoStack.axis = .horizontal
        infoStack.distribution = .fillEqually
        infoStack.spacing = 32
        infoStack.addArrangedSubview(distanceStack)
        infoStack.addArrangedSubview(timeStack)
        infoStack.addArrangedSubview(stepCountStack)
        
        topSeperatorLine.backgroundColor = .lightGray
        
        middleSeperatorLine.backgroundColor = .lightGray
        
        bottomSeperatorLine.backgroundColor = .lightGray
        
        
    }
    
    private func configureUI() {
        
        todayLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            $0.leading.equalToSuperview().inset(16)

        }
        
        infoStack.snp.makeConstraints {
            $0.top.equalTo(topSeperatorLine.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        walkEndLabel.snp.makeConstraints {
            $0.top.equalTo(middleSeperatorLine.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }
        
        walkShareButton.snp.makeConstraints {
            $0.top.equalTo(bottomSeperatorLine.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(52)
            $0.width.equalTo(343)
        }
        
        topSeperatorLine.snp.makeConstraints {
            $0.top.equalTo(todayLabel.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(1)
            $0.width.equalTo(332)
            
        }
        
        middleSeperatorLine.snp.makeConstraints {
            $0.top.equalTo(infoStack.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(1)
            $0.width.equalTo(332)
            
        }
        
        bottomSeperatorLine.snp.makeConstraints {
            $0.top.equalTo(walkEndLabel.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(1)
            $0.width.equalTo(332)
            
        }

    }
}
