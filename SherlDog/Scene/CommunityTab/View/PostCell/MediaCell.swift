//
//  MediaCell.swift
//  SherlDog
//
//  Created by 최규현 on 8/10/25.
//

import UIKit
import SnapKit
import Kingfisher

final class MediaCell: UICollectionViewCell {
    static let identifier = "MediaCell"
    
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    // 외부에서 URL 문자열을 받는 형태
    func settingCell(_ urlString: String) {
        let size = imageView.bounds.size
        
        let processor = DownsamplingImageProcessor(size: size)
        imageView.kf.indicatorType = .activity
        KF.url(URL(string: urlString))
            .placeholder(UIImage.logo)
            .setProcessor(processor)
            .cacheOriginalImage()
            .fade(duration: 0.25)
            .onFailureImage(UIImage(systemName: "exclamationmark.icloud"))
            .set(to: imageView)
    }
}

// MARK: - UI
private extension MediaCell {
    func setupUI() {
        contentView.addSubview(imageView)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
    
    func configureUI() {
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}
