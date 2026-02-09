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
            deleteButton
        ])
        
        imageView.image = UIImage(systemName: "plus.circle")?.withTintColor(.gray400)
        imageView.contentMode = .scaleAspectFit
        
        deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
    }
    
    private func configureUI() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        deleteButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview()
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
