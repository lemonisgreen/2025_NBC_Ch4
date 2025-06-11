//
//  PictureUploadRequestViewCell.swift
//  SherlDog
//
//  Created by 최규현 on 6/10/25.
//

import UIKit
import SnapKit

class PictureUploadRequestViewCell: UICollectionViewCell {

    static let identifier: String = "PictureUploadRequestViewCell"

    private let label = UILabel()
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func settingCell(text: String, imageName: String) {
        self.label.text = text
//        self.imageView.image = UIImage(named: imageName)
        imageView.image = UIImage(systemName: "camera.metering.center.weighted.average")
        imageView.tintColor = .textPrimary
    }

    private func setupUI() {
        [label, imageView].forEach {
            contentView.addSubview($0)
        }
        
        let cornerRadius: CGFloat = 12
        
        let selectedCell = UIView()
        selectedCell.layer.cornerRadius = cornerRadius
        selectedCell.backgroundColor = .gray100
        
        self.selectedBackgroundView = selectedCell

        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.borderColor = UIColor.gray200.cgColor
        contentView.layer.borderWidth = 1
        
        if self.isSelected {
            contentView.layer.borderColor = UIColor.textPrimary.cgColor
        }

        label.font = .title2
        label.textColor = .textPrimary
    }

    private func configureUI() {
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(30)
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }

        label.snp.makeConstraints {
            $0.leading.equalTo(imageView.snp.trailing).offset(16)
            $0.centerY.equalToSuperview()
        }
    }
}
