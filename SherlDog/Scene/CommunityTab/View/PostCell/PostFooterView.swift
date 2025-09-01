//
//  PostFooterView.swift
//  SherlDog
//
//  Created by 최규현 on 8/10/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import RxSwift
import RxCocoa

final class PostFooterView: UICollectionReusableView {
    static let identifier = "PostFooterView"
    
    var disposeBag = DisposeBag()
    
    private let container = UIStackView()
    private let actionBar = UIStackView()
    private let pageControl = UIPageControl()
    private let captionLabel = UILabel()
    private let likeButton = UIButton()
    private let previewCommentButton = UIButton()
    
    // MARK: - Initialize
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        captionLabel.text = nil
        likeButton.setTitle(nil, for: .normal)
        likeButton.imageView?.tintColor = .gray900
        previewCommentButton.setTitle(nil, for: .normal)
        pageControl.currentPage = 0
        pageControl.numberOfPages = 0
    }
    
    // MARK: - Method
    func settingCell(data: CommunityModel) {
        let likeButtonTitle = data.like.count > 0 ? String(data.like.count) : nil
        
        captionLabel.text = data.content
        
        likeButton.configuration?.title = likeButtonTitle
        likeButton.configuration?.image = self.isLiker(data)
        ? UIImage(systemName: "heart.fill")?.withTintColor(.keycolorPrimary2, renderingMode: .alwaysOriginal)
        : UIImage(systemName: "heart")?.withTintColor(.gray900, renderingMode: .alwaysOriginal)
        
        previewCommentButton.configuration?.title = String(data.previewComment.count)
        previewCommentButton.isHidden = (data.previewComment.isEmpty ? true : false)
    }
    
    func updatePage(total: Int, current: Int) {
        pageControl.numberOfPages = max(total, 0)
        pageControl.currentPage = min(max(current, 0), total - 1)
        pageControl.isHidden = (total <= 1)
    }
    
    private func isLiker(_ data: CommunityModel) -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else { return false }
        return data.like.contains(where: { $0 == userId })
    }
}

// MARK: - UI
extension PostFooterView {
    private func setupUI() {
        [likeButton, previewCommentButton]
            .forEach { actionBar.addArrangedSubview($0) }
        
        [captionLabel, actionBar]
            .forEach { container.addArrangedSubview($0) }
        
        addSubviews([
            container,
            pageControl
        ])
        
        container.axis = .vertical
        container.alignment = .leading
        container.spacing = 8
        
        actionBar.axis = .horizontal
        actionBar.spacing = 12
        
        pageControl.hidesForSinglePage = true
        pageControl.isUserInteractionEnabled = false
        pageControl.pageIndicatorTintColor = .keycolorDisabled
        pageControl.currentPageIndicatorTintColor = .keycolorPrimary1
        pageControl.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        captionLabel.font = .body5
        captionLabel.textColor = .textPrimary
        captionLabel.numberOfLines = 0
        captionLabel.lineBreakMode = .byTruncatingTail
        
        // MARK: - likeButton Configuration
        var likeButtonConfig = UIButton.Configuration.plain()
        likeButtonConfig.buttonSize = .mini
        likeButtonConfig.image = UIImage(systemName: "heart")?.withTintColor(.gray900, renderingMode: .alwaysOriginal)
        likeButtonConfig.baseForegroundColor = .gray900
        likeButtonConfig.title = ""
        likeButtonConfig.attributedTitle?.font = .body6
        likeButtonConfig.imagePadding = 4
        likeButtonConfig.contentInsets = .zero
        
        likeButton.configuration = likeButtonConfig
        
        // MARK: - previewCommentButton Configuration
        var commentButtonConfig = UIButton.Configuration.plain()
        commentButtonConfig.buttonSize = .mini
        commentButtonConfig.image = UIImage(systemName: "bubble")?.withTintColor(.gray900, renderingMode: .alwaysOriginal)
        commentButtonConfig.baseForegroundColor = .gray900
        commentButtonConfig.title = ""
        commentButtonConfig.attributedTitle?.font = .body6
        commentButtonConfig.imagePadding = 4
        commentButtonConfig.contentInsets = .zero
        
        previewCommentButton.configuration = commentButtonConfig
    }
    
    private func configureUI() {
        container.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(20)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalToSuperview().inset(-4)
            $0.leading.trailing.equalToSuperview()
        }
    }
}

extension PostFooterView {
    fileprivate var likeButtonTap: ControlEvent<Void> {
        self.likeButton.rx.tap
    }
}

extension Reactive where Base: PostFooterView {
    var likeButtonTap: ControlEvent<Void> {
        base.likeButtonTap
    }
}
