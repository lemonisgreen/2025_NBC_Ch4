//
//  ButtonFactory.swift
//  SherlDog
//
//  Created by 최규현 on 7/30/25.
//

import UIKit
import SnapKit

enum ButtonFactory {
    case main, sub
    
    static func makeButton(type: Self, title: String) -> UIButton {
        let button: UIButton
        
        switch type {
            case .main:
                button = ComponentButton()
            case .sub:
                button = ComponentSubButton()
        }
        
        (button as? ButtonComponent)?.configureUI(title: title)
        
        return button
    }
}
