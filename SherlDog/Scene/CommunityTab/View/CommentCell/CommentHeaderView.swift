//
//  CommentHeaderView.swift
//  SherlDog
//
//  Created by 최규현 on 11/12/25.
//
import UIKit
import SnapKit

class CommentHeaderView: UICollectionReusableView {

    static let identifier: String = "CommentHeaderView"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(title: String) {
        self.titleLabel.text = title
    }

    private func setupUI() {
        self.addSubview(titleLabel)

        titleLabel.font = .body1
        titleLabel.textColor = .textPrimary
        titleLabel.textAlignment = .left
    }

    private func configureUI() {
        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }
}
