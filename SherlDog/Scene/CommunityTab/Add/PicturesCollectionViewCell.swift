//
//  PicturesCollectionViewCell.swift
//  SherlDog
//
//  Created by 최규현 on 8/7/25.
//

import UIKit
import SnapKit

class PicturesCollectionViewCell: UICollectionViewCell {
    static let identifier = "PicturesCollectionViewCell"
    
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureUI()
    }
    
    override func prepareForReuse() {
        imageView.image = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ image: UIImage) {
        imageView.image = image
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        
        imageView.image = UIImage(systemName: "plus.circle")?.withTintColor(.gray400)
        imageView.contentMode = .scaleAspectFit
    }
    
    private func configureUI() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
