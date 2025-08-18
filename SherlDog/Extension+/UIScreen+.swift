//
//  IsIphoneSE+.swift
//  SherlDog
//
//  Created by JIN LEE on 7/18/25.
//

import UIKit

extension UIScreen {
    static var isIPhoneSE: Bool {
        return UIScreen.main.bounds.size == CGSize(width: 375, height: 667)
    }
    
    static var isIPhoneMini: Bool {
        return UIScreen.main.bounds.size == CGSize(width: 375, height: 812)
    }
}
