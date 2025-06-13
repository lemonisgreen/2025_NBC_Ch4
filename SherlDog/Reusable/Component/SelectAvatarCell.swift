//
//  SelectAvatarCell.swift
//  SherlDog
//
//  Created by 최규현 on 6/10/25.
//

import UIKit
import SnapKit

class SelectAvatarCell: UICollectionViewCell {
    static let identifier: String = "SelectAvatarCell"
    
    private let imageView = UIImageView()
    private let selectedImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func settingCell(imageName: String) {
        self.imageView.image = UIImage(systemName: imageName)
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        self.selectedBackgroundView = selectedImageView
        
        imageView.contentMode = .scaleAspectFit
        selectedImageView.contentMode = .scaleAspectFit
        selectedImageView.image = UIImage(systemName: "checkmark.square.fill")
        selectedImageView.tintColor = .gray400
    }
    
    private func configureUI() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(17)
        }
    }
}
