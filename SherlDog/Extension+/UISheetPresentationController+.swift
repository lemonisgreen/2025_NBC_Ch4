//
//  UISheetPresentationController+.swift
//  SherlDog
//
//  Created by 최규현 on 8/22/25.
//

import UIKit

/*
 onePet: 240
 twoPet: 320
 thrPet: 400
 clue: 650
 pictureWithoutAvatar: 260
 pictureWithAvatar: 340
 */

enum ModalSize {
    case medium, large, onePet, twoPet, thrPet, clue, pictureWithoutAvatar, pictureWithAvatar
    
    var setting: UISheetPresentationController.Detent {
        switch self {
        case .medium:
            return .medium()
        case .large:
            return .large()
        case .onePet:
            return .custom { _ in 240 }
        case .twoPet:
            return .custom { _ in 320 }
        case .thrPet:
            return .custom { _ in 400 }
        case .clue:
            return .custom { _ in 650 }
        case .pictureWithoutAvatar:
            return .custom { _ in 260 }
        case .pictureWithAvatar:
            return .custom { _ in 340 }
        }
    }
}

extension UISheetPresentationController {
    func setModalSize(type: ModalSize, grabber: Bool) {
        let result = type.setting
        
        self.detents = [result]
        self.preferredCornerRadius = 20
        self.prefersGrabberVisible = grabber
        self.selectedDetentIdentifier = result == .large() ? .large : .medium
    }
}
