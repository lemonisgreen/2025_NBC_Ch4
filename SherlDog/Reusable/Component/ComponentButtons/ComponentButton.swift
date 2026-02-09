//
//  ButtonManager.swift
//  SherlDog
//
//  Created by 전원식 on 6/10/25.
//

import UIKit
import SnapKit

class ComponentButton: ComponentButtonBase {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureUI(title: String) {
        super.configureUI(title: title)
        
        setTitleColor(.textInverse, for: .normal)
        setTitleColor(.gray100, for: .highlighted)
        
        setBackgroundColor(.keycolorPrimary3, for: .normal)
        setBackgroundColor(.keycolorPrimary1, for: .highlighted)
        setBackgroundColor(.textDisabled, for: .disabled)
    }
    
}
