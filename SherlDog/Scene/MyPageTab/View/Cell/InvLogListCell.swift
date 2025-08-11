//
//  InvLogListCell.swift
//  SherlDog
//
//  Created by 최규현 on 6/25/25.
//

import UIKit
import RxSwift
import RxCocoa

class InvLogListCell: UICollectionViewCell {
    static let identifier: String = "InvLogListCell"
    
    var disposeBag = DisposeBag()
    
    // MARK: - UI Property
    private let dateLabel = UILabel()
    private let caseNumberLabel = UILabel()
    private let symbolImageView = UIImageView()
    private let dataLabel = UILabel()
    private let deleteButton = UIButton()
    private let showButton = UIButton()
    private let buttonStackView = UIStackView()
    private let separatorView = UIView()
    
    // MARK: - Initialize
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.disposeBag = DisposeBag()
    }
}

extension InvLogListCell {
    
    func settingCell(data: WalkResultToList) {
        self.dateLabel.text = data.date
        self.caseNumberLabel.text = "CASE # \(data.caseNumber)"
        self.dataLabel.text = "\(data.distance)  ·  \(data.duration)  ·  \(data.steps)"
    }
    
    private func setup() {
        [deleteButton, showButton].forEach { buttonStackView.addArrangedSubview($0) }
        
        contentView.addSubviews([
            dateLabel,
            caseNumberLabel,
            symbolImageView,
            dataLabel,
            buttonStackView,
            separatorView
        ])
        
        dateLabel.font = .body5
        dateLabel.textColor = .textSecondary
        
        caseNumberLabel.font = .body4
        caseNumberLabel.textColor = .textPrimary
        
        symbolImageView.contentMode = .scaleAspectFit
        symbolImageView.image = UIImage(systemName: "pawprint.fill")
        symbolImageView.tintColor = .gray400
        
        dataLabel.font = .alert1
        dataLabel.textColor = .gray400
        
        [deleteButton, showButton].forEach {
            $0.setTitleColor(.textPrimary, for: .normal)
            $0.setBackgroundColor(.gray200, for: .normal)
            $0.layer.cornerRadius = 6
            $0.clipsToBounds = true
        }
        
        deleteButton.setTitle("삭제", for: .normal)
        deleteButton.titleLabel?.font = .body4
        
        showButton.setTitle("수사일지 보기", for: .normal)
        showButton.titleLabel?.font = .body1
        
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fill
        
        separatorView.backgroundColor = .gray200
    }
    
    private func configureUI() {
        dateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(24)
            $0.leading.equalToSuperview().inset(20.5)
        }
        
        caseNumberLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(8)
            $0.leading.equalTo(dateLabel)
        }
        
        dataLabel.snp.makeConstraints {
            $0.top.equalTo(caseNumberLabel)
            $0.trailing.equalToSuperview().inset(20.5)
        }
        
        symbolImageView.snp.makeConstraints {
            $0.height.width.equalTo(16)
            $0.centerY.equalTo(dataLabel)
            $0.trailing.equalTo(dataLabel.snp.leading).offset(-2)
        }
        
        deleteButton.snp.makeConstraints {
            $0.width.equalTo(showButton).multipliedBy(1.0 / 5.0)
        }
        
        buttonStackView.snp.makeConstraints {
            $0.height.equalTo(46)
            $0.top.equalTo(caseNumberLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16.5)
            $0.bottom.equalTo(separatorView.snp.top).offset(-24)
        }
        
        separatorView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
    
}

extension InvLogListCell {
    fileprivate var deleteButtonTapEvent: ControlEvent<Void> {
        deleteButton.rx.tap
    }
    
    fileprivate var showButtonTapEvent: ControlEvent<Void> {
        showButton.rx.tap
    }
}

extension Reactive where Base: InvLogListCell {
    var deleteButtonTap: ControlEvent<Void> {
        base.deleteButtonTapEvent
    }
    
    var showButtonTap: ControlEvent<Void> {
        base.showButtonTapEvent
    }
}
