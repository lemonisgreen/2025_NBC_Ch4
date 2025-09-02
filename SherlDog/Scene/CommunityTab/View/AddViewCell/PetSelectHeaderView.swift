//
//  PetSelectHeaderView.swift
//  SherlDog
//
//  Created by 최규현 on 9/2/25.
//

import UIKit
import SnapKit

// MARK: - 헤더 뷰
final class PetSelectHeaderView: UICollectionReusableView {
    static let identifier: String = "PetSelectHeaderView"
    
    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
