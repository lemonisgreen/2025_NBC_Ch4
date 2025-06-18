//
//  ButtonManager.swift
//  SherlDog
//
//  Created by 전원식 on 6/10/25.
//

import UIKit
import SnapKit

class ButtonManager: UIButton {
    
    init(title: String) {
        super.init(frame: .zero)
        configureUI(title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI(title: String) {
        
        setTitle(title, for: .normal)
        titleLabel?.font = UIFont.highlight4
        layer.cornerRadius = 6
        clipsToBounds = true
        
        setTitleColor(.textInverse, for: .normal)
        setTitleColor(.gray100, for: .highlighted)
        
        setBackgroundColor(.keycolorPrimary3, for: .normal)
        setBackgroundColor(.keycolorPrimary1, for: .highlighted)
        setBackgroundColor(.textDisabled, for: .disabled)
        
        self.snp.makeConstraints {
            $0.height.equalTo(52)
        }
    }
    
}
