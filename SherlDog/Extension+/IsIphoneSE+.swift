//
//  IsIphoneSE+.swift
//  SherlDog
//
//  Created by JIN LEE on 7/18/25.
//

import UIKit

extension UIScreen {
    static var isIPhoneSE: Bool {
        return UIScreen.main.bounds.height <= 667 // SE 2/3세대(667)
    }
}
