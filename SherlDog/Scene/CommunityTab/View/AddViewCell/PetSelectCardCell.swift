//
//  PetSelectCardCell.swift
//  SherlDog
//
//  Created by 최규현 on 9/2/25.
//

import UIKit
import SnapKit
import Kingfisher

// MARK: - 카드 셀
final class PetSelectCardCell: UICollectionViewListCell {
    static let identifier: String = "PetSelectCardCell"
    
    private let container = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selectedBackgroundView?.frame = container.frame
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        profileImageView.image = nil
        nameLabel.text = nil
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
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
//        contentView.backgroundColor = .keycolorBackground
        
        let bg = UIBackgroundConfiguration.clear()
        backgroundConfiguration = bg   // 기본 list 배경 제거
        
        // selectedView
        let selectedView = UIView()
        selectedView.backgroundColor = .keycolorPrimary2.withAlphaComponent(0.1)
        selectedView.layer.borderColor = UIColor.keycolorPrimary2.cgColor
        selectedView.layer.borderWidth = 1
        selectedBackgroundView = selectedView
        selectedBackgroundView?.layer.cornerRadius = 12
        selectedBackgroundView?.clipsToBounds = true
        
        // container
        contentView.addSubview(container)
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        container.backgroundColor = .clear
        
        // icon
        container.addSubview(profileImageView)
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 16
        profileImageView.clipsToBounds = true
        
        // title
        container.addSubview(nameLabel)
        nameLabel.font = .body2
        nameLabel.textColor = .textPrimary
    }
    
    private func configureUI() {
        container.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        profileImageView.snp.makeConstraints {
            $0.size.equalTo(32)
            $0.left.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints {
            $0.left.equalTo(profileImageView.snp.right).offset(10)
            $0.top.bottom.equalToSuperview().inset(12)
        }
    }
}
