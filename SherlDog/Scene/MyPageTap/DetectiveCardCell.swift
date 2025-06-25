//
//  DetectiveCardCell.swift
//  SherlDog
//
//  Created by 전원식 on 6/25/25.
//
import UIKit
import SnapKit

class DetectiveCardCell: UICollectionViewCell {
    static let identifier = "DetectiveCardCell"
    let cardView = DetectiveCardView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
