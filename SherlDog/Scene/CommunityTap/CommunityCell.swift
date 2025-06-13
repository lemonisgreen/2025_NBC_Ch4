//
//  CommunityCell.swift
//  SherlDog
//
//  Created by 최규현 on 6/12/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - CommunityCell
class CommunityCell: UICollectionViewCell {
    static let identifier = "CommunityCell"
    
    private let disposeBag = DisposeBag()
    
//    weak var delegate: CommunityCellDelegate?
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let infoLabel = UILabel()
    private let nameInfoStackView = UIStackView()
    private let profileStackView = UIStackView()
    private let postDateLabel = UILabel()
    private let contentImageView = UIImageView()
    private let contentLabel = UILabel()
    // 더보기 버튼 관련 코드들은 추후 작업 예정입니다.
//    private let moreShowButton = UIButton()
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureUI()
//        bind()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        profileImageView.image = nil
        nameLabel.text = nil
        infoLabel.text = nil
        postDateLabel.text = nil
        contentImageView.image = nil
        contentLabel.text = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Method
    func settingCell(data: CommunityModel) {
        profileImageView.image = data.profileImage
        nameLabel.text = data.name
        infoLabel.text = data.info
        postDateLabel.text = data.postDate
        contentImageView.image = data.contentImage
        contentLabel.text = data.content
        
//        contentLabel.numberOfLines = data.isExpanded ? 0 : 2
//        moreShowButton.setTitle(data.isExpanded ? "닫기" : "더보기", for: .normal)
    }
    
//    private func bind() {
//        self.moreShowButton.rx.tap
//            .subscribe(onNext: { [weak self] _ in
//                guard let self else { return }
//                self.delegate?.didTapMoreShowButton(in: self)
//            })
//            .disposed(by: disposeBag)
//    }
    
    private func setupUI() {
        [nameLabel, infoLabel].forEach {
            nameInfoStackView.addArrangedSubview($0)
        }
        
        [profileImageView, nameInfoStackView].forEach {
            profileStackView.addArrangedSubview($0)
        }
        
        contentView.addSubviews([
            profileStackView,
            postDateLabel,
            contentImageView,
            contentLabel,
//            moreShowButton
        ])
        
        nameInfoStackView.axis = .vertical
        nameInfoStackView.alignment = .leading
        nameInfoStackView.spacing = 2
        
        profileStackView.axis = .horizontal
        profileStackView.spacing = 8
        
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 16
        profileImageView.clipsToBounds = true
        
        nameLabel.font = .body4
        nameLabel.textColor = .textPrimary
        
        infoLabel.font = .alert2
        infoLabel.textColor = .textTertiary
        
        postDateLabel.font = .alert2
        postDateLabel.textColor = .textTertiary
        
        contentImageView.contentMode = .scaleAspectFill
        contentImageView.layer.cornerRadius = 4
        contentImageView.clipsToBounds = true
        
        contentLabel.font = .body5
        contentLabel.textColor = .textPrimary
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byTruncatingTail
        
//        moreShowButton.setTitle("더보기", for: .normal)
//        moreShowButton.setTitleColor(.gray400, for: .normal)
//        moreShowButton.titleLabel?.font = .title6
    }
    
    private func configureUI() {
        profileImageView.snp.makeConstraints {
            $0.width.height.equalTo(32)
        }
        
        profileStackView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(12)
        }
        
        postDateLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalTo(profileStackView)
        }
        
        contentImageView.snp.makeConstraints {
            $0.height.equalTo(192)
            $0.top.equalTo(profileStackView.snp.bottom).offset(10)
            $0.horizontalEdges.equalToSuperview().inset(12)
        }
        
        contentLabel.snp.makeConstraints {
            $0.top.equalTo(contentImageView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(20)
        }
        
//        moreShowButton.snp.makeConstraints {
//            $0.bottom.equalToSuperview()
//            $0.trailing.equalToSuperview().inset(12)
//        }
    }
}
