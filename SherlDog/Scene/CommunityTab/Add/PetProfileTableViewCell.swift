//
//  PetProfileTableViewCell.swift
//  SherlDog
//
//  Created by 최규현 on 8/7/25.
//

import UIKit
import SnapKit
import Kingfisher

class PetProfileTableViewCell: UITableViewCell {
    static let identifier: String = "PetProfileTableViewCell"
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let selectedView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUI()
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func settingCell(data: PetProfile) {
        self.nameLabel.text = data.name
        
        let processor = DownsamplingImageProcessor(size: self.profileImageView.bounds.size)
        
        profileImageView.kf.indicatorType = .activity
        KF.url(URL(string: data.image))
            .placeholder(UIImage.petAvatar)
            .setProcessor(processor)
            .cacheOriginalImage()
            .fade(duration: 0.25)
            .onFailureImage(UIImage.petAvatar)
            .onSuccess { result in }
            .onFailure { error in }
            .set(to: self.profileImageView)
    }
    
    private func setupUI() {
        contentView.backgroundColor = .keycolorBackground
        
        contentView.addSubviews([
            profileImageView,
            nameLabel
        ])
        
        selectedView.backgroundColor = .gray400
        selectedBackgroundView = selectedView
        
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        
        nameLabel.font = .body1
        nameLabel.textColor = .textPrimary
    }
    
    private func configureUI() {
        let profileSize: CGFloat = 32
        
        profileImageView.layer.cornerRadius = profileSize / 2
        
        profileImageView.snp.makeConstraints {
            $0.width.height.equalTo(profileSize)
            $0.leading.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalTo(profileImageView)
        }
    }
}
