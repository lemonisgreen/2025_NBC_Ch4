//
//  MediaCell.swift
//  SherlDog
//
//  Created by 최규현 on 8/10/25.
//

import UIKit
import SnapKit
import Kingfisher
import RxSwift
import RxCocoa

final class MediaCell: UICollectionViewCell {
    static let identifier = "MediaCell"
    
    private let imageView = UIImageView()
    private let petProfileStackView = UIStackView()
    private let doubleTap = UITapGestureRecognizer()
    
    var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = nil
        petProfileStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        disposeBag = DisposeBag()
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
            .onFailureImage(UIImage(systemName: "xmark"))
            .set(to: imageView)
    }
    
    func settingPetProfile(profile: [PetProfile]) {
        profile.forEach {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 18
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.layer.borderWidth = 1
            imageView.snp.makeConstraints { $0.size.equalTo(36) }
            
            imageView.kf.indicatorType = .activity
            let processor = DownsamplingImageProcessor(size: CGSize(width: 36, height: 36))
            KF.url(URL(string: $0.image))
                .placeholder(UIImage.logo)
                .setProcessor(processor)
                .cacheOriginalImage()
                .fade(duration: 0.25)
                .onFailureImage(UIImage(systemName: "xmark"))
                .set(to: imageView)
            
            self.petProfileStackView.addArrangedSubview(imageView)
        }
    }
}

// MARK: - UI
extension MediaCell {
    private func setupUI() {
        contentView.addSubviews([
            imageView,
            petProfileStackView
        ])
        
        addGestureRecognizer(doubleTap)
        
        doubleTap.numberOfTapsRequired = 2
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        petProfileStackView.axis = .horizontal
        petProfileStackView.spacing = -18
        petProfileStackView.alignment = .center
    }
    
    private func configureUI() {
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        petProfileStackView.snp.makeConstraints {
            $0.leading.top.equalToSuperview().inset(12)
        }
    }
}

extension MediaCell {
    fileprivate var MediadoubleTap: ControlEvent<UITapGestureRecognizer> {
        self.doubleTap.rx.event
    }
}

extension Reactive where Base: MediaCell {
    var mediaDoubleTap: ControlEvent<UITapGestureRecognizer> {
        base.MediadoubleTap
    }
}
