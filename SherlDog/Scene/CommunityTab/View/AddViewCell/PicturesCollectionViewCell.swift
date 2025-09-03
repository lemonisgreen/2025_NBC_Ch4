//
//  PicturesCollectionViewCell.swift
//  SherlDog
//
//  Created by 최규현 on 8/7/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class PicturesCollectionViewCell: UICollectionViewCell {
    static let identifier = "PicturesCollectionViewCell"
    
    var disposeBag = DisposeBag()
    
    private let imageView = UIImageView()
    private let deleteButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureUI()
    }
    
    override func prepareForReuse() {
        imageView.image = nil
        
        disposeBag = DisposeBag()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ image: UIImage) {
        imageView.image = image
    }
    
    private func setupUI() {
        contentView.addSubviews([
            imageView,
//            deleteButton
        ])
        
        addSubview(deleteButton)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        let xmarkImage = UIImage(systemName: "xmark.circle.fill")?.withTintColor(.gray800, renderingMode: .alwaysOriginal)
        deleteButton.setImage(xmarkImage, for: .normal)
    }
    
    private func configureUI() {
        imageView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalToSuperview().inset(8)
        }
        
        deleteButton.snp.makeConstraints {
            $0.height.width.equalTo(24)
            $0.top.equalToSuperview()
            $0.trailing.equalToSuperview().inset(-6)
        }
    }
}

extension PicturesCollectionViewCell {
    fileprivate var deleteButtonTap: ControlEvent<Void> {
        self.deleteButton.rx.tap
    }
}

extension Reactive where Base: PicturesCollectionViewCell {
    var deleteButtonTap: ControlEvent<Void> {
        base.deleteButtonTap
    }
}
