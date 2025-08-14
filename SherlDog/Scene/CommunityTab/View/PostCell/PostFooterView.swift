//
//  PostFooterView.swift
//  SherlDog
//
//  Created by 최규현 on 8/10/25.
//

import UIKit
import SnapKit

final class PostFooterView: UICollectionReusableView {
    static let identifier = "PostFooterView"
    
    private let container = UIStackView()
    private let actionBar = UIStackView()
    private let pageControl = UIPageControl()
    private let likesLabel = UILabel()
    private let captionLabel = UILabel()
    private let commentPreviewLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        likesLabel.text = nil
        captionLabel.text = nil
        commentPreviewLabel.text = nil
        pageControl.currentPage = 0
        pageControl.numberOfPages = 0
    }
    
    func settingCell(data: CommunityModel) {
        captionLabel.text = data.content
//        likesLabel.text = data.likeCount > 0 ? "좋아요 \(data.likeCount)개" : nil
//        commentPreviewLabel.text = data.previewComment // 없다면 숨김
//        commentPreviewLabel.isHidden = (data.previewComment?.isEmpty ?? true)
    }
    
    func updatePage(total: Int, current: Int) {
        pageControl.numberOfPages = max(total, 0)
        pageControl.currentPage = min(max(current, 0), total - 1)
        pageControl.isHidden = (total <= 1)
    }
}

private extension PostFooterView {
    func setupUI() {
        addSubviews([
            container,
            pageControl
        ])
        
        container.axis = .vertical
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
        
        // 여기에 버튼들 추가 가능 (아이콘 버튼 등)
        // let likeButton = UIButton(type: .system) ...
        // actionBar.addArrangedSubview(likeButton)
        
        likesLabel.font = .alert2
        likesLabel.textColor = .textPrimary
        
        commentPreviewLabel.font = .alert2
        commentPreviewLabel.textColor = .textTertiary
        commentPreviewLabel.numberOfLines = 1
        
        [
//            actionBar,
//            likesLabel,
            captionLabel,
//            commentPreviewLabel
        ].forEach {
            container.addArrangedSubview($0)
        }
    }
    
    func configureUI() {
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
