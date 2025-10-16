//
//  PostHeaderView.swift
//  SherlDog
//
//  Created by 최규현 on 6/12/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Kingfisher
import FirebaseFirestore
import FirebaseAuth

final class PostHeaderView: UICollectionReusableView {
    static let identifier = "PostHeaderView"
    
    var disposeBag = DisposeBag()
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let infoLabel = UILabel()
    private let nameInfoStackView = UIStackView()
    private let horizontalStackView = UIStackView()
    private let configButton = UIButton()
    private let tap = UITapGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        profileImageView.image = nil
        nameLabel.text = nil
        infoLabel.text = nil
        disposeBag = DisposeBag()
    }
    
    // MARK: - Public
    func settingCell(data: CommunityModel) {
        nameLabel.text = data.name
        infoLabel.text = self.petProfilesToNames(data.petProfile)
        + SDLiteral.CommunityView.separateDot
        + timestampToDate(data.postDate)
        
        let size = CGSize(width: 32, height: 32)
        let processor = DownsamplingImageProcessor(size: size)
        profileImageView.kf.indicatorType = .activity
        KF.url(URL(string: data.profileImage))
            .placeholder(UIImage.petAvatar)
            .setProcessor(processor)
            .cacheOriginalImage()
            .fade(duration: 0.25)
            .onFailureImage(UIImage.petAvatar)
            .set(to: profileImageView)
    }
    
    func settingMenu(menu: UIMenu) {
        configButton.menu = menu
    }
}

// MARK: - Data mapping helpers
extension PostHeaderView {
    private func timestampToDate(_ time: Timestamp) -> String {
        let date = time.dateValue()
        let formatter = DateFormatter.todayStyle(date)
        
        return formatter.string(from: date)
    }
    
    private func petProfilesToNames(_ data: [PetProfile]) -> String {
        return data.map { $0.name }.joined(separator: " ")
    }
}

// MARK: - UI
private extension PostHeaderView {
    func setupUI() {
        nameInfoStackView.axis = .vertical
        nameInfoStackView.alignment = .leading
        nameInfoStackView.spacing = 2
        
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = 8
        
        [nameLabel, infoLabel].forEach { nameInfoStackView.addArrangedSubview($0) }
        [profileImageView, nameInfoStackView].forEach { horizontalStackView.addArrangedSubview($0) }
        
        addSubviews([
            horizontalStackView,
            configButton
        ])
        
        horizontalStackView.addGestureRecognizer(tap)
        
        // 스타일
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 8
        profileImageView.clipsToBounds = true
        
        nameLabel.font = .body4
        nameLabel.textColor = .textPrimary
        
        infoLabel.font = .alert2
        infoLabel.textColor = .gray500
        
        configButton.setTitle(SDLiteral.CommunityView.dotdotdot, for: .normal)
        configButton.setTitleColor(.textPrimary, for: .normal)
        configButton.titleLabel?.font = .body1
        configButton.showsMenuAsPrimaryAction = true
    }
    
    func configureUI() {
        profileImageView.snp.makeConstraints {
            $0.size.equalTo(32)
        }
        
        horizontalStackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(12)
            $0.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(configButton.snp.leading).offset(-8)
        }
        
        configButton.setContentHuggingPriority(.required, for: .horizontal)
        configButton.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(horizontalStackView)
        }
    }
}

extension PostHeaderView {
    fileprivate var profileTap: ControlEvent<Void> {
        return ControlEvent<Void>(
            events: tap.rx.event
                .filter { $0.state == .ended }
                .map { _ in }
        )
    }
}

extension Reactive where Base: PostHeaderView {
    var profileTap: ControlEvent<Void> {
        return base.profileTap
    }
}
