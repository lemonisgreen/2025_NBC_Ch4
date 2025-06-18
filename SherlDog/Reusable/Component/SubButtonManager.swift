//
//  SubButtonManager.swift
//  SherlDog
//
//  Created by 최규현 on 6/18/25.
//

import UIKit

class SubButtonManager: UIButton {
    
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
        layer.borderColor = ColorForState.enabled.getColor().cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 6
        clipsToBounds = true
        
        setTitleColor(ColorForState.enabled.getColor(), for: .normal)
        setTitleColor(ColorForState.highlighted.getColor(), for: .highlighted)
        setTitleColor(ColorForState.disabled.getColor(), for: .disabled)
        
        setBackgroundColor(.textInverse, for: .normal)
        setBackgroundColor(.gray100, for: .highlighted)
        
        self.snp.makeConstraints {
            $0.height.equalTo(52)
        }
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
    
    private func setBackgroundColor(_ color: UIColor, for state: UIButton.State) {
        let renderer = UIGraphicsImageRenderer(size: .init(width: 1, height: 1))
        
        let image = renderer.image { context in
            color.setFill()
            context.fill(.init(origin: .zero, size: .init(width: 1, height: 1)))
        }
        
        setBackgroundImage(image, for: state)
    }
    
}
