//
//  RegistrationSearchButton.swift
//  SherlDog
//
//  Created by Jin Lee on 6/10/25.
//

import UIKit
import SnapKit

class RegistrationSearchButton: UIButton {
    
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
        self.backgroundColor = .gray50
        self.setTitleColor(.textDisabled, for: .normal)
        self.titleLabel?.textAlignment = .left
        self.titleLabel?.font = .body3
        self.layer.cornerRadius = 6
        self.snp.makeConstraints {
            $0.height.equalTo(44)
        }
    }
}
