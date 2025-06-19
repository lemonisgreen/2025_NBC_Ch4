//
//  ViewCapture+.swift
//  SherlDog
//
//  Created by 최규현 on 6/18/25.
//

import UIKit

extension UIView {
    func viewCapture() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        
        let image = renderer.image { context in
            layer.render(in: context.cgContext)
        }
        
        return image
    }
}
