//
//  RegistrationSelectButton.swift
//  SherlDog
//
//  Created by Jin Lee on 6/10/25.
//

import UIKit
import SnapKit

class RegistrationSelectButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(title: String) {
        super.init(frame: .zero)
        self.setTitle(title, for: .normal)
        setConfig()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setConfig() {
        self.isSelected = false
        self.setTitleColor(.textTertiary, for: .normal)
        self.setTitleColor(.textPrimary, for: .selected)
        self.titleLabel?.textAlignment = .center
        self.titleLabel?.font = .title3
        self.layer.cornerRadius = 6
        self.snp.makeConstraints {
            $0.height.equalTo(48)
        }
    }
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .keycolorPrimary5 : .keycolorInverse
            layer.borderColor = isSelected ? UIColor.keycolorPrimary2.cgColor : UIColor.clear.cgColor
            layer.borderWidth = isSelected ? 1.0 : 0.0
        }
    }
}
