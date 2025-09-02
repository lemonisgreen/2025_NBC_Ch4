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
        var bg = UIBackgroundConfiguration.clear()
        backgroundConfiguration = bg   // 기본 list 배경 제거

        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        container.backgroundColor = .secondarySystemGroupedBackground
        contentView.addSubview(container)

        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.tintColor = .label
        profileImageView.layer.cornerRadius = 14
        profileImageView.clipsToBounds = true

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .preferredFont(forTextStyle: .body)

        container.addSubview(profileImageView)
        container.addSubview(nameLabel)

        let inset: CGFloat = 8
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            profileImageView.widthAnchor.constraint(equalToConstant: 28),
            profileImageView.heightAnchor.constraint(equalToConstant: 28),
            profileImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            nameLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        // 선택 시 카드만 하이라이트
        let selectedBG = UIView()
        selectedBG.backgroundColor = UIColor.systemFill
        selectedBackgroundView = selectedBG
        selectedBackgroundView?.layer.cornerRadius = 12
        selectedBackgroundView?.clipsToBounds = true
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
        
    }
    
    private func configureUI() {
        
    }
}
