//
//  PostHeaderView.swift
//  SherlDog
//
//  Created by 최규현 on 6/12/25.
//

import UIKit
import SnapKit
import Kingfisher
import FirebaseFirestore

final class PostHeaderView: UICollectionReusableView {
    static let identifier = "PostHeaderView"
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let infoLabel = UILabel()
    private let nameInfoStackView = UIStackView()
    private let hStack = UIStackView()
    private let dateLabel = UILabel()
    
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
        dateLabel.text = nil
    }
    
    // MARK: - Public
    func settingCell(data: CommunityModel) {
        nameLabel.text = data.name
        infoLabel.text = data.info
        dateLabel.text = timestampToDate(data.postDate)
        
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
}

// MARK: - Data mapping helpers
extension PostHeaderView {
    private func timestampToDate(_ time: Timestamp) -> String {
        let date = time.dateValue()
        let formatter = DateFormatter()
        
        formatter.dateFormat = checkToday(date)
        ? setTodayStyle(date)
        : "M월 d일"
        
        return formatter.string(from: date)
    }
    
    private func setTodayStyle(_ date: Date) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(date)
        
        if diff < 60 {
            return "방금 전"
        } else if diff < 3600 {
            return "\(Int(diff / 60))분 전"
        } else {
            return "\(Int(diff / 3600))시간 전"
        }
    }
    
    private func checkToday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let otherDay = calendar.startOfDay(for: date)
        return today == otherDay
    }
}

// MARK: - UI
private extension PostHeaderView {
    func setupUI() {
        nameInfoStackView.axis = .vertical
        nameInfoStackView.alignment = .leading
        nameInfoStackView.spacing = 2
        
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 8
        
        [nameLabel, infoLabel].forEach { nameInfoStackView.addArrangedSubview($0) }
        [profileImageView, nameInfoStackView].forEach { hStack.addArrangedSubview($0) }
        
        addSubview(hStack)
        addSubview(dateLabel)
        
        // 스타일
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 16
        profileImageView.clipsToBounds = true
        
        nameLabel.font = .body4
        nameLabel.textColor = .textPrimary
        
        infoLabel.font = .alert2
        infoLabel.textColor = .textTertiary
        
        dateLabel.font = .alert2
        dateLabel.textColor = .textTertiary
    }
    
    func configureUI() {
        profileImageView.snp.makeConstraints {
            $0.size.equalTo(32)
        }
        
        hStack.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview().inset(12)
            $0.trailing.lessThanOrEqualTo(dateLabel.snp.leading).offset(-8)
        }
        
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)
        dateLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalTo(hStack)
        }
    }
}
