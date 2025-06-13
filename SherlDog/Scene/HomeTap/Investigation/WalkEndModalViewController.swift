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
    let dogImages: [UIImage] = [
        UIImage(named: "walkEndDog")!,
        UIImage(named: "walkEndDog")!,
        UIImage(named: "walkEndDog")!
    ]
    let walkEndLabel = UILabel()
    let walkShareButton = UIButton()
    let mapImageView = UIImageView()
    
    let dogImagesStack = UIStackView()
    let walkEndStack = UIStackView()
    let infoStack = UIStackView()
    let timeStack = UIStackView()
    let distanceStack = UIStackView()
    let stepCountStack = UIStackView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
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
            walkEndLabel,
            walkShareButton,
            infoStack,
            timeStack,
            distanceStack,
            stepCountStack,
            mapImageView,
            walkEndStack
        ].forEach {
            view.addSubview($0)
        }
        
        backgroundImageView.image = UIImage(named: "endInvestigaionAddLine")
        backgroundImageView.contentMode = .scaleAspectFit
        view.insertSubview(backgroundImageView, at: 0)
        
        todayLabel.text = "2025/06/05"
        todayLabel.textColor = UIColor(named: "keycolorPrimary2")
        todayLabel.font = UIFont.title3
        todayLabel.textAlignment = .left
        todayLabel.backgroundColor = .clear
        
        distanceLabel.text = "거리"
        distanceLabel.textColor = UIColor(named: "textTertiary")
        distanceLabel.textAlignment = .left
        distanceLabel.font = UIFont.body6
        distanceLabel.backgroundColor = .clear
        
        timeLabel.text = "시간"
        timeLabel.textColor = UIColor(named: "textTertiary")
        timeLabel.textAlignment = .left
        timeLabel.font = UIFont.body6
        timeLabel.backgroundColor = .clear
        
        stepCountLabel.text = "걸음수"
        stepCountLabel.textColor = UIColor(named: "textTertiary")
        stepCountLabel.textAlignment = .left
        stepCountLabel.font = UIFont.body6
        stepCountLabel.backgroundColor = .clear
        
        distanceContentLabel.text = "11.23km"
        distanceContentLabel.textColor = UIColor(named: "textSecondary")
        distanceContentLabel.font = UIFont.highlight3
        distanceContentLabel.backgroundColor = .clear
        
        timeContentLabel.text = "10:11:12"
        timeContentLabel.textColor = UIColor(named: "textSecondary")
        timeContentLabel.font = UIFont.highlight3
        timeContentLabel.backgroundColor = .clear
        
        stepCountContentLabel.text = "12345"
        stepCountContentLabel.textColor = UIColor(named: "textSecondary")
        stepCountContentLabel.font = UIFont.highlight3
        stepCountContentLabel.backgroundColor = .clear
        
        walkEndStack.arrangedSubviews.forEach {
            walkEndStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        walkEndLabel.textColor = UIColor(named: "textSecondary")
        walkEndLabel.font = UIFont.title1
        walkEndLabel.backgroundColor = .clear
        walkEndStack.axis = .horizontal
        walkEndStack.alignment = .center
        walkEndStack.backgroundColor = .clear
        walkEndStack.spacing = 4
        walkEndStack.addArrangedSubview(dogImagesStack)
        walkEndStack.addArrangedSubview(walkEndLabel)
        
        for dogImage in dogImages {
            let imageView = UIImageView(image: dogImage)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.snp.makeConstraints {
                $0.width.height.equalTo(32)
            }
            dogImagesStack.addArrangedSubview(imageView)
        }
        
        if dogImages.count == 1 {
            walkEndLabel.text = "멍탐정과 함께 수사 완료!"
        } else {
            walkEndLabel.text = "멍탐정들과 함께 수사 완료!"
        }
        
        dogImagesStack.axis = .horizontal
        dogImagesStack.spacing = -20
        dogImagesStack.alignment = .center
        dogImagesStack.backgroundColor = .clear
        
        mapImageView.image = UIImage(named: "mapPolaroid")
        mapImageView.contentMode = .scaleAspectFit
        mapImageView.backgroundColor = .clear
        
        walkShareButton.setTitle("수사 일지 공유하기", for: .normal)
        walkShareButton.titleLabel?.font = UIFont.highlight4
        walkShareButton.setTitleColor(UIColor(named: "textInverse"), for: .normal)
        walkShareButton.backgroundColor = UIColor(named: "keycolorPrimary3")
        walkShareButton.layer.cornerRadius = 6
        
        distanceStack.axis = .vertical
        distanceStack.spacing = 4
        distanceStack.alignment = .leading
        distanceStack.addArrangedSubview(distanceLabel)
        distanceStack.addArrangedSubview(distanceContentLabel)
        distanceStack.backgroundColor = .clear
        
        timeStack.axis = .vertical
        timeStack.spacing = 4
        timeStack.alignment = .leading
        timeStack.addArrangedSubview(timeLabel)
        timeStack.addArrangedSubview(timeContentLabel)
        timeStack.backgroundColor = .clear
        
        stepCountStack.axis = .vertical
        stepCountStack.spacing = 4
        stepCountStack.alignment = .leading
        stepCountStack.addArrangedSubview(stepCountLabel)
        stepCountStack.addArrangedSubview(stepCountContentLabel)
        stepCountStack.backgroundColor = .clear
        
        infoStack.axis = .horizontal
        infoStack.distribution = .fillEqually
        infoStack.spacing = 25
        infoStack.addArrangedSubview(distanceStack)
        infoStack.addArrangedSubview(timeStack)
        infoStack.addArrangedSubview(stepCountStack)
        infoStack.backgroundColor = .clear
    }
    
    private func configureUI() {
        backgroundImageView.snp.makeConstraints {
            $0.top.bottom.equalTo(view)
            $0.centerX.equalToSuperview()
        }
        
        todayLabel.snp.makeConstraints {
            $0.top.equalTo(backgroundImageView.snp.top).offset(65)
            $0.leading.equalTo(backgroundImageView.snp.leading).inset(60)
        }
        
        infoStack.snp.makeConstraints {
            $0.top.equalTo(todayLabel.snp.bottom).offset(70)
            $0.leading.trailing.equalToSuperview().inset(35)
        }
        
        walkEndStack.snp.makeConstraints {
            $0.top.equalTo(infoStack.snp.bottom).offset(40)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(50)
            $0.leading.equalToSuperview().inset(48)
        }
        
        mapImageView.snp.makeConstraints {
            $0.top.equalTo(walkEndStack.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(10)
            $0.height.equalTo(260)
        }
        
        walkShareButton.snp.makeConstraints {
            $0.top.equalTo(mapImageView.snp.bottom).offset(32)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(52)
            $0.leading.trailing.equalToSuperview().inset(28)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        dismiss(animated: true, completion: nil)
    }
}
