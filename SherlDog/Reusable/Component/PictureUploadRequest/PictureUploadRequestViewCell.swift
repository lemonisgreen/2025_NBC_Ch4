//
//  PictureUploadRequestViewCell.swift
//  SherlDog
//
//  Created by 최규현 on 6/10/25.
//

import UIKit
import SnapKit
import Kingfisher

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
        
        // 이미지 이름으로 로드
        if !imageName.hasPrefix("http") {
            self.imageView.image = UIImage(named: imageName)
        
            // URL에서 이미지 로드
        } else if let url = URL(string: imageName) {
            let processor = DownsamplingImageProcessor(size: self.imageView.bounds.size) // 크기 지정 다운 샘플링
            
            self.imageView.kf.indicatorType = .activity
            KF.url(url)
                .placeholder(UIImage.petAvatar)
                .setProcessor(processor)
                .cacheOriginalImage()
                .fade(duration: 0.25)
                .onFailureImage(UIImage.petAvatar)
                .onSuccess { result in }
                .onFailure { error in }
                .set(to: self.imageView)
        }
    }
    
    private func setupUI() {
        [label, imageView].forEach {
            contentView.addSubview($0)
        }
        
        let cornerRadius: CGFloat = 12
        
        let selectedCell = UIView()
        selectedCell.layer.cornerRadius = cornerRadius
        selectedCell.backgroundColor = .keycolorPrimary1Opacity
        selectedCell.layer.borderColor = UIColor.keycolorPrimary2.cgColor
        selectedCell.layer.borderWidth = 1
        
        self.selectedBackgroundView = selectedCell
        
        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.borderColor = UIColor.gray300.cgColor
        contentView.layer.borderWidth = 1
        
        if self.isSelected {
            contentView.layer.borderColor = UIColor.textPrimary.cgColor
        }
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        label.font = .title2
        label.textColor = .textPrimary
    }
    
    private func configureUI() {
        let imageSize: CGFloat = 36
        
        imageView.layer.cornerRadius = imageSize / 2
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(imageSize)
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
        
        label.snp.makeConstraints {
            $0.leading.equalTo(imageView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }
    }
}
