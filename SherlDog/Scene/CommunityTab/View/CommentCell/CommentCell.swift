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
import RxSwift
import RxCocoa

final class CommentCell: UICollectionViewCell {
    static let identifier: String = "CommentCell"
    
    var disposeBag = DisposeBag()
    private let contentLabelFont = UIFont.body6
    private lazy var maxContentHeight: CGFloat = {
        let lineHeight = contentLabelFont.lineHeight
        let textInset = contentTextView.textContainerInset.top + contentTextView.textContainerInset.bottom
        let contentInset = contentTextView.contentInset.top + contentTextView.contentInset.bottom
        // 3줄 + 인셋
        return lineHeight * 3 + textInset + contentInset
    }()
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let postDateLabel = UILabel()
    private let nameDateStackView = UIStackView()
    private let contentLabel = UILabel()
    private let contentTextView = UITextView()
    private let verticalStackView = UIStackView()
    private let horizontalStackView = UIStackView()
    private let configButton = UIButton()
    private let saveButton = UIButton()
    private let cancelButton = UIButton()
    private let buttonStackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        profileImageView.image = nil
        nameLabel.text = nil
        postDateLabel.text = nil
        contentLabel.text = nil
        contentTextView.text = nil
        disposeBag = DisposeBag()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setFixMode(isFixMode: Bool) {
        contentTextView.isHidden = !isFixMode
        contentLabel.isHidden = isFixMode
        configButton.isHidden = isFixMode
        buttonStackView.isHidden = !isFixMode
        
        if isFixMode {
            self.contentTextView.becomeFirstResponder()
        }
    }
    
    func cancelEditMode() {
        self.contentTextView.text = self.contentLabel.text
    }
    
    func loadFixedContent() -> String {
        guard let text = self.contentTextView.text else { return "" }
        return text
    }
    
    func settingCell(data: CommentModel, canOpen: Bool) {
        if canOpen {
            self.nameLabel.text = data.user.nickname
            self.postDateLabel.text = SDLiteral.CommunityView.separateDot
            + self.timestampToToday(timestamp: data.date)
            self.contentLabel.text = data.content
            self.contentTextView.text = data.content
            
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
        } else {
            self.postDateLabel.text = self.timestampToToday(timestamp: data.date)
            self.contentLabel.text = SDLiteral.PostDetailViewController.secretCommentContent
            self.contentTextView.text = SDLiteral.PostDetailViewController.secretCommentContent
            self.profileImageView.image = .secretProfile
        }
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
            postDateLabel
        ].forEach { nameDateStackView.addArrangedSubview($0) }
        
        [
            nameDateStackView,
            contentLabel
        ].forEach { verticalStackView.addArrangedSubview($0) }
        
        [
            profileImageView,
            verticalStackView
        ].forEach { horizontalStackView.addArrangedSubview($0) }
        
        [
            cancelButton,
            saveButton
        ].forEach { buttonStackView.addArrangedSubview($0) }
        
        contentView.addSubviews([
            horizontalStackView,
            contentTextView,
            configButton,
            buttonStackView
        ])
        
        nameDateStackView.axis = .horizontal
        nameDateStackView.spacing = 2
        nameDateStackView.alignment = .fill
        
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 2
        verticalStackView.alignment = .leading
        
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 12
        horizontalStackView.alignment = .top
        
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 8
        buttonStackView.alignment = .trailing
        buttonStackView.isHidden = true
        
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 10
        profileImageView.clipsToBounds = true
        
        nameLabel.font = .body4
        nameLabel.textColor = .textPrimary
        
        postDateLabel.font = .body6
        postDateLabel.textColor = .gray400
        
        contentLabel.font = self.contentLabelFont
        contentLabel.textColor = .textPrimary
        contentLabel.numberOfLines = 0
        
        contentTextView.layer.borderColor = UIColor.textPrimary.cgColor
        contentTextView.layer.borderWidth = 1
        contentTextView.backgroundColor = .clear
        contentTextView.font = self.contentLabelFont
        contentTextView.textColor = .textPrimary
        contentTextView.isHidden = true
        
        configButton.setTitle(SDLiteral.CommunityView.dotdotdot, for: .normal)
        configButton.setTitleColor(.textPrimary, for: .normal)
        configButton.titleLabel?.font = .body1
        configButton.showsMenuAsPrimaryAction = true
        
        saveButton.setTitle("저장", for: .normal)
        saveButton.setTitleColor(.textPrimary, for: .normal)
        saveButton.titleLabel?.font = .body4
        
        cancelButton.setTitle("취소", for: .normal)
        cancelButton.setTitleColor(.textAlert, for: .normal)
        cancelButton.titleLabel?.font = .body4
    }
    
    private func configureUI() {
        profileImageView.snp.makeConstraints {
            $0.size.equalTo(40)
        }
        
        horizontalStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        configButton.snp.makeConstraints {
            $0.centerY.equalTo(nameLabel)
            $0.trailing.equalToSuperview()
        }
        
        buttonStackView.snp.makeConstraints {
            $0.centerY.equalTo(nameLabel)
            $0.trailing.equalToSuperview()
        }
        
        contentTextView.snp.makeConstraints {
            $0.top.leading.equalTo(contentLabel)
            $0.trailing.equalToSuperview()
            $0.height.equalTo(self.maxContentHeight)
        }
    }
}

extension CommentCell {
    fileprivate var saveButtonTap: ControlEvent<Void> {
        saveButton.rx.tap
    }
    
    fileprivate var cancelButtonTap: ControlEvent<Void> {
        cancelButton.rx.tap
    }
}

extension Reactive where Base: CommentCell {
    var saveButtonTap: ControlEvent<Void> {
        base.saveButtonTap
    }
    
    var cancelButtonTap: ControlEvent<Void> {
        base.cancelButtonTap
    }
}
