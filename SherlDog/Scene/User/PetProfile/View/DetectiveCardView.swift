//
//  DetectiveCardView.swift
//  SherlDog
//
//  Created by Jin Lee on 6/5/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class DetectiveCardView: UIView {
    
    var onEditTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?
    
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
    
    private let menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureUI()
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
        
        self.addSubview(menuButton)
        setupMenu()
        
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.gray600.cgColor
        self.backgroundColor = .keycolorSecondary3
        
        detectiveHeaderBackgroundView.backgroundColor = .keycolorSecondary2
        detectiveHeaderBackgroundView.layer.borderWidth = 1
        detectiveHeaderBackgroundView.layer.borderColor = UIColor.gray600Opacity.cgColor
        
        detectiveCardLabel.text = SDLiteral.DetectiveCardView.detectiveCardLabelTitle
        detectiveCardLabel.font = UIFont.cardTitle
        detectiveCardLabel.textColor = .white
        
        detectiveNumberLabel.text = SDLiteral.DetectiveCardView.detectiveNumberLabeTitle
        detectiveNumberLabel.font = UIFont.alert2
        detectiveNumberLabel.textColor = .white
        
        detectiveNumber.font = UIFont.cardTitle
        detectiveNumber.textColor = .white
        
        detectivePhotoImageView.layer.cornerRadius = 4
        detectivePhotoImageView.clipsToBounds = true
        detectivePhotoImageView.layer.borderWidth = 1
        detectivePhotoImageView.layer.borderColor = UIColor.gray600Opacity.cgColor
        
        detectiveNameLabel.text = SDLiteral.DetectiveCardView.detectiveNameLabelTitle
        detectiveNameLabel.verticalAlignment = .top
        detectiveNameLabel.font = UIFont.alert1
        detectiveNameLabel.textColor = .gray700
        
        detectiveName.font = UIFont.body4
        detectiveName.textColor = .gray900
        
        detectiveBreedLabel.text = SDLiteral.DetectiveCardView.detectiveBreedLabelTItle
        detectiveBreedLabel.verticalAlignment = .top
        detectiveBreedLabel.font = UIFont.alert1
        detectiveBreedLabel.textColor = .gray700
        
        detectiveBreed.font = UIFont.body4
        detectiveBreed.textColor = .gray900
        
        detectiveAgeLabel.text = SDLiteral.DetectiveCardView.detectiveAgeLabelTitle
        detectiveAgeLabel.verticalAlignment = .top
        detectiveAgeLabel.font = UIFont.alert1
        detectiveAgeLabel.textColor = .gray700
        
        detectiveAge.font = UIFont.body4
        detectiveAge.textColor = .gray900
        
        detectiveIntroduceLabel.text = SDLiteral.DetectiveCardView.detectiveIntroduceLabelTitle
        detectiveIntroduceLabel.verticalAlignment = .top
        detectiveIntroduceLabel.font = UIFont.alert1
        detectiveIntroduceLabel.textColor = .gray700
        
        detectiveIntroduceBackgroundView.layer.cornerRadius = 24 / 2
        detectiveIntroduceBackgroundView.layer.masksToBounds = true
        detectiveIntroduceBackgroundView.backgroundColor = .keycolorOpacity
        
        detectiveIntroduce.font = UIFont.title5
        detectiveIntroduce.textColor = .textSecondary
    }
    
    // 메뉴 버튼 설정
    private func setupMenu() {
        let editAction = UIAction(title: "수정하기", image: UIImage(systemName: "pencil")) { [weak self] _ in
            self?.onEditTapped?()
            print("✅ 수정하기 눌림") // 테스트 로그 출력
        }
        
        let deleteAction = UIAction(title: "삭제하기", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // 삭제 확인 커스텀 알럿 생성
            let alert = CustomAlertViewController(
                message: "정말 삭제하시겠습니까?",
                subMessage: "삭제된 프로필은 되돌릴 수 없습니다.",
                buttons: [
                    CustomAlertViewController.AlertButton(
                        title: "취소",
                        action: nil
                    ),
                    CustomAlertViewController.AlertButton(
                        title: "삭제",
                        action: { [weak self] in
                            self?.onDeleteTapped?()
                        }
                    )
                ]
            )
            self.parentViewController?.present(alert, animated: true)
        }
        menuButton.menu = UIMenu(children: [editAction, deleteAction])
        menuButton.showsMenuAsPrimaryAction = true
    }
    
    private func configureUI() {
        
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
        
        menuButton.snp.makeConstraints {
            $0.bottom.trailing.equalToSuperview().inset(12)
            $0.width.height.equalTo(32)
        }
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let vc = next as? UIViewController { return vc }
            responder = next
        }
        return nil
    }
}
