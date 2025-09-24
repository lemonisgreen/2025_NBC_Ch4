//
//  BlockedUserListCell.swift
//  SherlDog
//
//  Created by JIN LEE on 9/16/25.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

class BlockedUserListCell: UITableViewCell {
    
    static let reuseIdentifier = "BlockedUserListCell"
    
    var disposeBag = DisposeBag()
    
    private let profileImageView = UIImageView()
    private let profileLabel = UILabel()
    let selectButton = UIButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUI()
        configureUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        profileImageView.image = nil
        profileLabel.text = nil
        selectButton.isSelected = false
    }
    
    private func setupUI() {
        
        contentView.addSubviews([
            profileImageView,
            profileLabel,
            selectButton])
        
        selectionStyle = .none
        backgroundColor = .keycolorTertiaryBG
        
        selectButton.setImage(UIImage(systemName: "circle"), for: .normal)
        selectButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        selectButton.tintColor = .keycolorSecondary2
        
        profileImageView.layer.cornerRadius = 8
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = .keycolorTertiaryBG
        
        profileLabel.font = .body2
        profileLabel.textColor = .label
    }
    
    private func configureUI() {
        
        profileImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }
        profileLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }
        selectButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(18)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }
    }
    
    func configure(withNickname nickname: String, selected: Bool, imageUrlString: String) {
        profileLabel.text = nickname
        selectButton.isSelected = selected

        if let url = URL(string: imageUrlString) {
            profileImageView.kf.setImage(with: url, placeholder: UIImage(named: "defaultProfile"))
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
        }
    }
    
    var selectTapped: Observable<Void> {
        selectButton.rx.tap.asObservable()
    }
    
}
