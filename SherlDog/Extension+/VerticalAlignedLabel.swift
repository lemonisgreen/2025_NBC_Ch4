//
//  VerticalAlignedLabel.swift
//  SherlDog
//
//  Created by Jin Lee on 6/7/25.
//

import UIKit

class VerticalAlignedLabel: UILabel {
    enum VerticalAlignment {
        case top, middle, bottom
    }

    var verticalAlignment: VerticalAlignment = .middle {
        didSet { setNeedsDisplay() }
    }

    override func drawText(in rect: CGRect) {
        guard let text = self.text else {
            super.drawText(in: rect)
            return
        }
        var newRect = rect
        let size = self.sizeThatFits(rect.size)
        switch verticalAlignment {
        case .top:
            newRect.size.height = size.height
        case .middle:
            newRect.origin.y += (rect.size.height - size.height) / 2
            newRect.size.height = size.height
        case .bottom:
            newRect.origin.y += rect.size.height - size.height
            newRect.size.height = size.height
        }
        super.drawText(in: newRect)
    }
}
