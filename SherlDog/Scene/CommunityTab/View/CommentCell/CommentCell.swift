//
//  CommentCell.swift
//  SherlDog
//
//  Created by 최규현 on 9/30/25.
//

import UIKit
import SnapKit
import Kingfisher
import FirebaseFirestore

final class CommentCell: UICollectionViewCell {
    static let identifier: String = "CommentCell"
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let petNamesLabel = UILabel()
    private let contentLabel = UITextField()
    private let verticalStackView = UIStackView()
    private let horizontalStackView = UIStackView()
    private let configButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        profileImageView.image = nil
        nameLabel.text = nil
        petNamesLabel.text = nil
        contentLabel.text = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func settingCell(data: CommentModel) {
        self.nameLabel.text = data.user.nickname
        self.contentLabel.text = data.content
        self.petNamesLabel.text = ""
        + SDLiteral.CommunityView.separateDot
        + self.timestampToToday(timestamp: data.date)
        
        let processor = DownsamplingImageProcessor(size: .init(width: 40, height: 40)) // 크기 지정 다운 샘플링
        
        self.profileImageView.kf.indicatorType = .activity
        KF.url(URL(string: data.user.image))
            .placeholder(UIImage.petAvatar)
            .setProcessor(processor)
            .cacheOriginalImage()
            .fade(duration: 0.25)
            .onFailureImage(UIImage.secretProfile)
            .onSuccess { result in }
            .onFailure { error in }
            .set(to: self.profileImageView)
        
    }
    
    func settingMenu(menu: UIMenu) {
        self.configButton.menu = menu
    }
    
    private func timestampToToday(timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        
        let dateFormatter = DateFormatter.todayStyle(date)
        
        return dateFormatter.string(from: date)
    }
    
    // MARK: - UI
    private func setupUI() {
        [
            nameLabel,
            petNamesLabel,
            contentLabel
        ].forEach { verticalStackView.addArrangedSubview($0) }
        
        [
            profileImageView,
            verticalStackView
        ].forEach { horizontalStackView.addArrangedSubview($0) }
        
        contentView.addSubviews([
            horizontalStackView,
            configButton
        ])
        
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 2
        verticalStackView.alignment = .leading
        
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 12
        horizontalStackView.alignment = .top
        
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 8
        profileImageView.clipsToBounds = true
        
        nameLabel.font = .body4
        nameLabel.textColor = .textPrimary
        
        petNamesLabel.font = .body6
        petNamesLabel.textColor = .gray400
        
        contentLabel.borderStyle = .none
        contentLabel.isEnabled = false
        contentLabel.font = .body6
        contentLabel.textColor = .textPrimary
        
        configButton.setTitle(SDLiteral.CommunityView.dotdotdot, for: .normal)
        configButton.setTitleColor(.textPrimary, for: .normal)
        configButton.titleLabel?.font = .body1
        configButton.showsMenuAsPrimaryAction = true
    }
    
    private func configureUI() {
        profileImageView.snp.makeConstraints {
            $0.size.equalTo(40)
        }
        
        horizontalStackView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
        }
        
        configButton.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.top)
            $0.trailing.equalToSuperview()
        }
    }
}
