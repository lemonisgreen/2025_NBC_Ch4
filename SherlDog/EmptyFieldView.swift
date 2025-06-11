//
//  EmptyFieldView.swift
//  SherlDog
//
//  Created by Jin Lee on 6/10/25.
//
import UIKit
import SnapKit

class EmptyFieldView: UIView {

    private var heightConstraint: Constraint?

    init(height: CGFloat = 44, color: UIColor = .gray50) {
        super.init(frame: .zero)
        self.backgroundColor = color
        configureUI(height: height)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI(height: CGFloat) {
        self.layer.cornerRadius = 6
        self.snp.makeConstraints { make in
            heightConstraint = make.height.equalTo(height).constraint
        }
    }
}

