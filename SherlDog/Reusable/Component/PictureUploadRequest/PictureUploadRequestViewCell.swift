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
        if imageName.hasPrefix("http") {
            imageView.snp.updateConstraints {
                $0.width.height.equalTo(36)
            }
            // URL에서 이미지 로드
            if let url = URL(string: imageName) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.imageView.image = image
                            self.imageView.contentMode = .scaleAspectFill
                            self.imageView.clipsToBounds = true
                            self.imageView.layer.cornerRadius = self.imageView.frame.width / 2
                        }
                    }
                }
            }
        } else {
            // 기존 방식 (번들 이미지)
            imageView.snp.updateConstraints {
                $0.width.height.equalTo(32)
            }
            self.imageView.image = UIImage(named: imageName)
            self.imageView.tintColor = .textPrimary
            //self.imageView.contentMode = .scaleAspectFit
        }
    }
    
    private func setupUI() {
        [label, imageView].forEach {
            contentView.addSubview($0)
        }
        
        let cornerRadius: CGFloat = 12
        
        let selectedCell = UIView()
        selectedCell.layer.cornerRadius = cornerRadius
        selectedCell.backgroundColor = .gray100
        selectedCell.layer.borderColor = UIColor.gray300.cgColor
        selectedCell.layer.borderWidth = 1
        
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
            $0.width.height.equalTo(32)
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
        
        label.snp.makeConstraints {
            $0.leading.equalTo(imageView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }
    }
}
