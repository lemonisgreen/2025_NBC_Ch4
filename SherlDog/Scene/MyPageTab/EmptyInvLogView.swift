//
//  EmptyInvLogView.swift
//  SherlDog
//
//  Created by JIN LEE on 7/31/25.
//

import UIKit
import SnapKit

final class EmptyInvLogView: UIView {
    
    private let emptyInvLogImageView = UIImageView()
    private let emptyInvLogLabel = UILabel()
    private let emptyInvLogTipLabel = UILabel()
    
    
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
            emptyInvLogImageView,
            emptyInvLogLabel,
            emptyInvLogTipLabel
        ])
        
        emptyInvLogImageView.image = UIImage(named: "emptyInvLogDog")
        
        emptyInvLogLabel.text = "아직 수사일지가 없어요"
        emptyInvLogLabel.textColor = .textDisabled
        emptyInvLogLabel.font = .body2
        
        emptyInvLogTipLabel.text = "첫 번째 수사를 시작해 기록을 쌓아보세요"
        emptyInvLogTipLabel.textColor = .textDisabled
        emptyInvLogTipLabel.font = .alert2
    }
    
    private func configureUI() {
        
        emptyInvLogImageView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(134)
            $0.centerX.equalToSuperview()
        }
        
        emptyInvLogLabel.snp.makeConstraints {
            $0.top.equalTo(emptyInvLogImageView.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        
        emptyInvLogTipLabel.snp.makeConstraints {
            $0.top.equalTo(emptyInvLogLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
    }
}
