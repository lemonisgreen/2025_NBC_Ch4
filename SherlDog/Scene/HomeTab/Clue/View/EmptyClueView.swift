//
//  EmptyClueView.swift
//  SherlDog
//
//  Created by JIN LEE on 7/31/25.
//

import UIKit
import SnapKit

final class EmptyClueView: UIView {
    
    private let emptyClueImageView = UIImageView()
    private let emptyClueLabel = UILabel()
    private let emptyClueTipLabel = UILabel()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        self.addSubviews([
            emptyClueImageView,
            emptyClueLabel,
            emptyClueTipLabel
        ])
        
        emptyClueImageView.image = UIImage(named: "emptyClueDog")
        
        emptyClueLabel.text = "이 날 남긴 단서가 없어요"
        emptyClueLabel.textColor = .textDisabled
        emptyClueLabel.font = .body2
        
        emptyClueTipLabel.text = "Tip. 산책 중에 특별한 순간을 발견했을 때\n사진을 찍고 메모를 남겨보세요."
        emptyClueTipLabel.textColor = .textDisabled
        emptyClueTipLabel.font = .alert2
        emptyClueTipLabel.numberOfLines = 2
        emptyClueTipLabel.textAlignment = .center
    }
    
    private func configureUI() {
        emptyClueImageView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(194)
            $0.centerX.equalToSuperview()
        }
        
        emptyClueLabel.snp.makeConstraints {
            $0.top.equalTo(emptyClueImageView.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        
        emptyClueTipLabel.snp.makeConstraints {
            $0.top.equalTo(emptyClueLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
    }
}
