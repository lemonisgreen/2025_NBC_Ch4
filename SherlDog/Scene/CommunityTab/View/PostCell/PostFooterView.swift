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
    private let tap = UITapGestureRecognizer()
    
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
        likeButton.setImage(nil, for: .normal)
        previewCommentButton.setTitle(nil, for: .normal)
        pageControl.currentPage = 0
        pageControl.numberOfPages = 0
    }
    
    // MARK: - Method
    func settingCell(data: CommunityModel, collection: FirestoreCollection) {
        let likeButtonTitle = data.likeCount > 0 ? String(data.likeCount) : ""
        
        captionLabel.text = data.content
        
        self.isLiker(data, collection: collection)
        likeButton.configuration?.attributedTitle = AttributedString(
            likeButtonTitle,
            attributes: AttributeContainer([.font: UIFont.body6])
        )
        
        previewCommentButton.configuration?.attributedTitle = AttributedString(
            String(data.commentCount),
            attributes: AttributeContainer([.font: UIFont.body6])
        )
        previewCommentButton.isHidden = (data.commentCount == 0 ? true : false)
    }
    
    func updatePage(total: Int, current: Int) {
        pageControl.numberOfPages = max(total, 0)
        pageControl.currentPage = min(max(current, 0), total - 1)
        pageControl.isHidden = (total <= 1)
    }
    
    private func isLiker(_ data: CommunityModel, collection: FirestoreCollection) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        CommunityActionManager.shared.isLiked(collection: collection, postCode: data.documentId, userId: userId)
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] isLiked in
                self?.likeButton.configuration?.image = isLiked
                ? UIImage(systemName: "heart.fill")?.withTintColor(.keycolorPrimary2, renderingMode: .alwaysOriginal)
                : UIImage(systemName: "heart")?.withTintColor(.gray900, renderingMode: .alwaysOriginal)
            }
            .disposed(by: disposeBag)
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
        
        container.addGestureRecognizer(tap)
        
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
        captionLabel.numberOfLines = 2
        captionLabel.lineBreakMode = .byTruncatingTail
        
        // MARK: - likeButton Configuration
        var likeButtonConfig = UIButton.Configuration.plain()
        likeButtonConfig.buttonSize = .mini
        likeButtonConfig.image = UIImage(systemName: "heart")?.withTintColor(.gray900, renderingMode: .alwaysOriginal)
        likeButtonConfig.baseForegroundColor = .gray900
        likeButtonConfig.attributedTitle = AttributedString(
            "",
            attributes: AttributeContainer([.font: UIFont.body6])
        )
        likeButtonConfig.imagePadding = 2
        likeButtonConfig.contentInsets = .zero
        
        likeButton.configuration = likeButtonConfig
        
        // MARK: - previewCommentButton Configuration
        var commentButtonConfig = UIButton.Configuration.plain()
        commentButtonConfig.buttonSize = .mini
        commentButtonConfig.image = UIImage(systemName: "bubble")?.withTintColor(.gray900, renderingMode: .alwaysOriginal)
        commentButtonConfig.baseForegroundColor = .gray900
        commentButtonConfig.attributedTitle = AttributedString(
            "",
            attributes: AttributeContainer([.font: UIFont.body6])
        )
        commentButtonConfig.imagePadding = 2
        commentButtonConfig.contentInsets = .zero
        
        previewCommentButton.configuration = commentButtonConfig
    }
    
    private func configureUI() {
        container.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(8)
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
    
    fileprivate var containerTap: ControlEvent<Void> {
        return ControlEvent<Void>(events: Observable.merge(
            self.tap.rx.event
                .filter { $0.state == .ended }
                .map { _ in },
            self.previewCommentButton.rx.tap.asObservable()
        ))
    }
}

extension Reactive where Base: PostFooterView {
    var likeButtonTap: ControlEvent<Void> {
        base.likeButtonTap
    }
    
    var containerTap: ControlEvent<Void> {
        base.containerTap
    }
}
