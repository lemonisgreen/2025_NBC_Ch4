//
//  SetBackgroundColor+.swift
//  SherlDog
//
//  Created by 최규현 on 6/18/25.
//

import UIKit

extension UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIButton.State) {
        let renderer = UIGraphicsImageRenderer(size: .init(width: 1, height: 1))
        
        let image = renderer.image { context in
            color.setFill()
            context.fill(.init(origin: .zero, size: .init(width: 1, height: 1)))
        }
        
        setBackgroundImage(image, for: state)
    }
}
