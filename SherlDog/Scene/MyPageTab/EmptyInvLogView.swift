//
//  EmptyInvLogView.swift
//  SherlDog
//
//  Created by JIN LEE on 7/31/25.
//

import UIKit
import SnapKit

extension ArchiveType {
    var emptyLabel: String {
        switch self {
        case .invLog:
            SDLiteral.ArchiveView.InvLog.emptyLabel
        case .clue:
            SDLiteral.ArchiveView.Clue.emptyLabel
        }
    }
    var emptyImage: String {
        switch self {
        case .invLog:
            SDLiteral.ArchiveView.InvLog.emptyImage
        case .clue:
            SDLiteral.ArchiveView.Clue.emptyImage
        }
    }
    var emptyTip: String {
        switch self {
        case .invLog:
            SDLiteral.ArchiveView.InvLog.emptyTip
        case .clue:
            SDLiteral.ArchiveView.Clue.emptyTip
        }
    }
}

final class EmptyInvLogView: UIView {
    
    private let emptyInvLogImageView = UIImageView()
    private let emptyInvLogLabel = UILabel()
    private let emptyInvLogTipLabel = UILabel()
    private let type: ArchiveType
    
    init(frame: CGRect, type: ArchiveType) {
        self.type = type
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
        
        emptyInvLogImageView.image = UIImage(named: self.type.emptyImage)
        
        emptyInvLogLabel.text = self.type.emptyLabel
        emptyInvLogLabel.textColor = .textDisabled
        emptyInvLogLabel.font = .body2
        
        emptyInvLogTipLabel.numberOfLines = 0
        emptyInvLogTipLabel.textAlignment = .center
        emptyInvLogTipLabel.text = self.type.emptyTip
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
