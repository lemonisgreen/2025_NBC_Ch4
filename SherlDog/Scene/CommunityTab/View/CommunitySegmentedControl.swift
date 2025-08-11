//
//  CommunitySegmentedControl.swift
//  SherlDog
//
//  Created by 최규현 on 8/6/25.
//

import UIKit
import SnapKit

final class CommunitySegmentedControl: UISegmentedControl {
    
    private enum State {
        case normal, selected
        
        var textFont: UIFont {
            switch self {
            case .normal: return UIFont.title1
            case .selected: return UIFont.title1
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .normal: return UIColor.keycolorDisabled
            case .selected: return UIColor.keycolorPrimary4
            }
        }
    }
    
    override var selectedSegmentIndex: Int {
        didSet {
            bottomLinePosition(animated: true)
        }
    }
    
    // MARK: - UIProperty
    private let bottomLine = UIView()
    
    // MARK: - Initialize
    override init(items: [Any]?) {
        super.init(items: items)
        
        removeBackgroundColor()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bottomLinePosition(animated: false)
    }
    
    // MARK: - Method
    private func bottomLinePosition(animated: Bool) {
        guard self.numberOfSegments > 0 else { return }
        
        let width = self.bounds.size.width / CGFloat(self.numberOfSegments)
        let height = 2.0
        let xPosition = CGFloat(self.selectedSegmentIndex * Int(width))
        let yPosition = self.bounds.size.height - 1.0
        
        let newFrame = CGRect(x: xPosition,
                              y: yPosition,
                              width: width,
                              height: height)
        
        if animated {
            self.bottomLine.frame = newFrame
            
        } else {
            UIView.animate(withDuration: 0.1) {
                self.bottomLine.frame = newFrame
            }
        }
    }
    
    private func removeBackgroundColor() {
        let emptyImage = UIImage()
        
        self.setBackgroundImage(emptyImage, for: .normal, barMetrics: .default)
        self.setBackgroundImage(emptyImage, for: .selected, barMetrics: .default)
        self.setBackgroundImage(emptyImage, for: .highlighted, barMetrics: .default)
        self.setDividerImage(emptyImage, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
    }
    
    private func setupUI() {
        addSubview(bottomLine)
        
        let normal = State.normal
        let selected = State.selected
        
        // normal 상태 설정
        self.setTitleTextAttributes([
            .font: normal.textFont,
            .foregroundColor: normal.textColor
        ], for: .normal)
        
        // selected 상태 설정
        self.setTitleTextAttributes([
            .font: selected.textFont,
            .foregroundColor: selected.textColor
        ], for: .selected)
        
        bottomLine.backgroundColor = selected.textColor
    }
}
