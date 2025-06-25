//
//  InvLogListCellEvent.swift
//  SherlDog
//
//  Created by 최규현 on 6/25/25.
//

import UIKit

protocol InvLogListCellEventDelegate: AnyObject {
    func deleteButtonTapEvent(_ cell: UICollectionViewCell)
    func showButtonTapEvent(_ cell: UICollectionViewCell)
}
