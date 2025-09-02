//
//  PetSelectCardCell.swift
//  SherlDog
//
//  Created by 최규현 on 9/2/25.
//

import UIKit
import SnapKit

// MARK: - 카드 셀
final class PetSelectCardCell: UICollectionViewListCell {
    private let container = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

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

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .label
        iconView.layer.cornerRadius = 14
        iconView.clipsToBounds = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .body)

        container.addSubview(iconView)
        container.addSubview(titleLabel)

        let inset: CGFloat = 8
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        // 선택 시 카드만 하이라이트
        let selectedBG = UIView()
        selectedBG.backgroundColor = UIColor.systemFill
        selectedBackgroundView = selectedBG
        selectedBackgroundView?.layer.cornerRadius = 12
        selectedBackgroundView?.clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, systemIcon: String) {
        titleLabel.text = title
        iconView.image = UIImage(systemName: systemIcon)
    }
}
