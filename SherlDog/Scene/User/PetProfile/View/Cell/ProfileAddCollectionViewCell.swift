//
//  Untitled.swift
//  SherlDog
//
//  Created by 최영락 on 6/16/25.
//

import SnapKit
import UIKit
import RxSwift
import RxCocoa

class ProfileAddCollectionViewCell: UICollectionViewCell {
    static let identifier = "ProfileAddCollectionViewCell"
    
    private let profileAddButton = UIButton()
    private let dogImageView = UIImageView()
    private let infoLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        profileAddButton.backgroundColor = UIColor.gray100
        profileAddButton.layer.cornerRadius = 16
        profileAddButton.layer.borderWidth = 1
        profileAddButton.layer.borderColor = UIColor.textTertiary.cgColor
        profileAddButton.isUserInteractionEnabled = false
        
        let buttonStack = makeProfileButtonStack()
        profileAddButton.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { $0.center.equalToSuperview() }
        
        contentView.addSubview(profileAddButton)
        profileAddButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func makeProfileButtonStack() -> UIStackView {
        let circleView = UIView()
        circleView.layer.cornerRadius = 30
        circleView.layer.borderWidth = 2
        circleView.layer.borderColor = UIColor.textTertiary.cgColor

        let plusImage = UIImageView(image: UIImage(systemName: "plus"))
        plusImage.tintColor = UIColor.textTertiary
        plusImage.contentMode = .scaleAspectFit
        circleView.addSubview(plusImage)
        plusImage.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(24) }
        circleView.snp.makeConstraints { $0.size.equalTo(60) }

        let titleLabel = UILabel()
        titleLabel.text = "프로필 추가하기"
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.textTertiary

        let stack = UIStackView(arrangedSubviews: [circleView, titleLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        return stack
    }
}
