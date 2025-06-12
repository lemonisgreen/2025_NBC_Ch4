//
//  WalkEndModalViewController.swift
//  SherlDog
//
//  Created by 전원식 on 6/9/25.
//

import UIKit

class WalkEndModalViewController : UIViewController {
    
    let backgroundImageView = UIImageView()
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
    let mapImageView = UIImageView()
    
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
            backgroundImageView,
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
            mapImageView,
            middleSeperatorLine,
            bottomSeperatorLine
        ].forEach {
            view.addSubview($0)
        }
        
        backgroundImageView.image = UIImage(named: "endInvestigation")
        backgroundImageView.contentMode = .scaleAspectFit
        view.insertSubview(backgroundImageView, at: 0)
        
        todayLabel.text = "2025.06.05"
        todayLabel.textColor = UIColor(named: "keycolorPrimary2")
        todayLabel.font = UIFont.title3
        todayLabel.textAlignment = .left
        
        distanceLabel.text = "거리"
        distanceLabel.textColor = UIColor(named: "textTertiary")
        distanceLabel.font = UIFont.body6
        
        timeLabel.text = "시간"
        timeLabel.textColor = UIColor(named: "textTertiary")
        timeLabel.font = UIFont.body6
        
        stepCountLabel.text = "걸음수"
        stepCountLabel.textColor = UIColor(named: "textTertiary")
        stepCountLabel.font = UIFont.body6
        
        distanceContentLabel.text = "11.23km"
        distanceContentLabel.textColor = UIColor(named: "textSecondary")
        distanceContentLabel.font = UIFont.highlight3
        
        timeContentLabel.text = "10:11:12"
        timeContentLabel.textColor = UIColor(named: "textSecondary")
        timeContentLabel.font = UIFont.highlight3
        
        stepCountContentLabel.text = "12345"
        stepCountContentLabel.textColor = UIColor(named: "textSecondary")
        stepCountContentLabel.font = UIFont.highlight3
        
        dogImage.image = UIImage(systemName: "pawprint.fill")
        
        walkEndLabel.text = "멍탐정들과 함께 수사 완료!"
        walkEndLabel.textColor = UIColor(named: "textSecondary")
        walkEndLabel.font = UIFont.title1
        
        mapImageView.image = UIImage(named: "mapPolaroid")
        
        walkShareButton.setTitle("수사 일지 공유하기", for: .normal)
        walkShareButton.titleLabel?.font = UIFont.highlight4
        walkShareButton.setTitleColor(UIColor(named: "textInverse"), for: .normal)
        walkShareButton.backgroundColor = UIColor(named: "keycolorPrimary3")
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
        
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
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
