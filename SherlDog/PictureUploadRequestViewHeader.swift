//
//  PictureUploadRequestViewHeader.swift
//  SherlDog
//
//  Created by 최규현 on 6/10/25.
//

import UIKit
import SnapKit

class PictureUploadRequestViewHeader: UICollectionReusableView {

    static let identifier: String = "PictureUploadRequestViewHeader"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(title: String) {
        self.titleLabel.text = title
    }

    private func setupUI() {
        self.addSubview(titleLabel)

        titleLabel.font = .title1
        titleLabel.textColor = .textPrimary
    }

    private func configureUI() {
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }
}
