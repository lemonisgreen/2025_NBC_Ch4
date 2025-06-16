//
//  AddSubviews+.swift
//  SherlDog
//
//  Created by JIN LEE on 6/12/25.
//

import UIKit

extension UIView {
    func addSubviews(_ views: [UIView]) {
        views.forEach { self.addSubview($0) }
    }
}
