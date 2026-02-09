//
//  ComponentButtonBase.swift
//  SherlDog
//
//  Created by 최규현 on 7/30/25.
//

import UIKit
import SnapKit

protocol ButtonComponent {
    func configureUI(title: String)
}

class ComponentButtonBase: UIButton, ButtonComponent {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureUI(title: String) {
        setTitle(title, for: .normal)
        
        titleLabel?.font = UIFont.highlight4
        layer.cornerRadius = 6
        clipsToBounds = true
        
        self.snp.makeConstraints {
            $0.height.equalTo(52)
        }
    }
}
