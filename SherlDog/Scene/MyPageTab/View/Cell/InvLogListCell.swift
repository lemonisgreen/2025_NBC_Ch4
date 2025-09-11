//
//  InvLogListCell.swift
//  SherlDog
//
//  Created by 최규현 on 6/25/25.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

class InvLogListCell: UICollectionViewCell {
    static let identifier: String = "InvLogListCell"
    
    var disposeBag = DisposeBag()
    private let tap = UITapGestureRecognizer()
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.selectedStateImageView.image = UIImage(systemName: "checkmark.circle")?
                    .withTintColor(.keycolorSecondary2, renderingMode: .alwaysOriginal)
            } else {
                self.selectedStateImageView.image = UIImage(systemName: "circle")?
                    .withTintColor(.gray200, renderingMode: .alwaysOriginal)
            }
        }
    }
    
    // MARK: - UI Property
    private let caseNumberLabel = UILabel()
    private let dateLabel = UILabel()
    private let symbolImageView = UIImageView()
    private let infoLabel = UILabel()
    private let selectedStateImageView = UIImageView()
    
    private let totalstackView = UIStackView()
    private let caseAndDateStackView = UIStackView()
    private let infoStackView = UIStackView()
    private let petProfileStackView = UIStackView()
    
    // MARK: - Initialize
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
        configureUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.layer.shadowPath = UIBezierPath(
            roundedRect: contentView.bounds,
            cornerRadius: contentView.layer.cornerRadius
        ).cgPath
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        caseNumberLabel.text = nil
        dateLabel.text = nil
        infoLabel.text = nil
        selectedStateImageView.image = nil
        contentView.gestureRecognizers?.removeAll()
        petProfileStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        self.disposeBag = DisposeBag()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InvLogListCell {
    
    func settingCell(data: WalkResultToList) {
        self.dateLabel.text = data.date
        self.caseNumberLabel.text = String(format: SDLiteral.InvLogListView.caseNumber, data.caseNumber)
        self.infoLabel.text = String(format: SDLiteral.InvLogListView.infoLabel,
                                     data.distance,
                                     data.duration,
                                     data.steps)
        
        data.petProfile.forEach { profile in
            let imageView = UIImageView()
            imageView.layer.cornerRadius = 18
            imageView.clipsToBounds = true
            
            imageView.snp.makeConstraints { $0.size.equalTo(36) }
            
            let processor = DownsamplingImageProcessor(size: .init(width: 36, height: 36))
            
            imageView.kf.indicatorType = .activity
            KF.url(URL(string: profile.image))
                .placeholder(UIImage.petAvatar)
                .setProcessor(processor)
                .cacheOriginalImage()
                .fade(duration: 0.25)
                .onFailureImage(UIImage.petAvatar)
                .onSuccess { result in }
                .onFailure { error in }
                .set(to: imageView)
            
            self.petProfileStackView.addArrangedSubview(imageView)
        }
    }
    
    func bind(isSelectMode: Driver<Bool>) {
        isSelectMode
            .drive(onNext: { [weak self] in self?.toggleSelectMode(selectable: $0) })
            .disposed(by: disposeBag)
    }
    
    private func toggleSelectMode(selectable: Bool) {
        self.selectedStateImageView.isHidden = !selectable
        
        selectable
        ? contentView.gestureRecognizers?.removeAll()
        : contentView.addGestureRecognizer(tap)
    }
    
    private func setup() {
        [
            caseNumberLabel,
            dateLabel
        ].forEach { caseAndDateStackView.addArrangedSubview($0) }
        
        [
            symbolImageView,
            infoLabel
        ].forEach { infoStackView.addArrangedSubview($0) }
        
        [
            caseAndDateStackView,
            infoStackView,
            petProfileStackView
        ].forEach { totalstackView.addArrangedSubview($0) }
        
        contentView.addSubviews([
            totalstackView,
            selectedStateImageView
        ])
        
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        
        // MARK: - contentView shadow
        contentView.layer.shadowOffset = .init(width: 0, height: 0)
        contentView.layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        contentView.layer.shadowOpacity = 1.0
        contentView.layer.shadowRadius = 3.0 // 기본 값
        
        totalstackView.axis = .vertical
        totalstackView.spacing = 8
        totalstackView.alignment = .leading
        
        caseAndDateStackView.axis = .vertical
        caseAndDateStackView.spacing = 2
        caseAndDateStackView.alignment = .leading
        
        infoStackView.axis = .horizontal
        infoStackView.spacing = 3
        infoStackView.alignment = .center
        
        petProfileStackView.axis = .horizontal
        petProfileStackView.spacing = -8
        petProfileStackView.alignment = .center
        
        caseNumberLabel.font = .title5
        caseNumberLabel.textColor = .gray500
        
        dateLabel.font = .body4
        dateLabel.textColor = .textPrimary
        
        symbolImageView.contentMode = .scaleAspectFit
        symbolImageView.image = UIImage(systemName: "pawprint.fill")
        symbolImageView.tintColor = .keycolorPrimary2
        
        infoLabel.font = .body1
        infoLabel.textColor = .gray700
        
        selectedStateImageView.image = UIImage(systemName: "circle")?
            .withTintColor(.gray200, renderingMode: .alwaysOriginal)
        selectedStateImageView.contentMode = .scaleAspectFit
        selectedStateImageView.isHidden = true
    }
    
    private func configureUI() {
        totalstackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
        
        symbolImageView.snp.makeConstraints { $0.size.equalTo(16) }
        
        selectedStateImageView.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(10)
        }
    }
    
}

extension InvLogListCell {
    fileprivate var cellTap: ControlEvent<Void> {
        ControlEvent(
            events: self.tap.rx.event
                .filter { $0.state == .ended }
                .map { _ in () }
        )
    }
}

extension Reactive where Base: InvLogListCell {
    var cellTap: ControlEvent<Void> {
        base.cellTap
    }
}
