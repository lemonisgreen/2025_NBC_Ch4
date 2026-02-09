//
//  SubButtonManager.swift
//  SherlDog
//
//  Created by 최규현 on 6/18/25.
//

import UIKit

class ComponentSubButton: ComponentButtonBase {
    
    enum ColorForState {
        case enabled
        case highlighted
        case disabled
        
        func getColor() -> UIColor {
            switch self {
            case .enabled:
                return .keycolorPrimary3
            case .highlighted:
                return .keycolorPrimary3.withAlphaComponent(0.4)
            case .disabled:
                return .textDisabled
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            setBorderColor()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            setBorderColor()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureUI(title: String) {
        super.configureUI(title: title)
        
        layer.borderColor = ColorForState.enabled.getColor().cgColor
        layer.borderWidth = 1
        
        setTitleColor(ColorForState.enabled.getColor(), for: .normal)
        setTitleColor(ColorForState.highlighted.getColor(), for: .highlighted)
        setTitleColor(ColorForState.disabled.getColor(), for: .disabled)
        
        setBackgroundColor(.textInverse, for: .normal)
        setBackgroundColor(.gray100, for: .highlighted)
    }
    
    private func setBorderColor() {
        if isEnabled {
            layer.borderColor = ColorForState.enabled.getColor().cgColor
            
        } else if isHighlighted {
            layer.borderColor = ColorForState.highlighted.getColor().cgColor
            
        } else if !isEnabled {
            layer.borderColor = ColorForState.disabled.getColor().cgColor
        }
    }
    
}
