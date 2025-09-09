//
//  PetSelectHeaderView.swift
//  SherlDog
//
//  Created by 최규현 on 9/2/25.
//

import UIKit
import SnapKit
import RxCocoa
import RxSwift

// MARK: - 헤더 뷰
final class PetSelectHeaderView: UICollectionReusableView {
    static let identifier = "PetSelectHeaderView"
    
    private let titleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
    private let tap = UITapGestureRecognizer()
    
    var disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureUI()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        titleLabel.text = nil
    }
    
    func setTitle(title: String) {
        titleLabel.text = title
    }

    func setDisclosure(isExpanded: Bool) {
        titleLabel.textColor = isExpanded ? .textPrimary : .gray500
        chevron.tintColor    = isExpanded ? .textPrimary : .gray500
        
        UIView.animate(withDuration: 0.1) {
            self.chevron.transform = isExpanded ? CGAffineTransform(rotationAngle: .pi) : .identity
        }
    }
    
    private func setupUI() {
        titleLabel.font = .body2
        titleLabel.textColor = .gray500
        
        chevron.tintColor = .gray500
        
        addGestureRecognizer(tap)

        addSubview(titleLabel)
        addSubview(chevron)
    }
    
    private func configureUI() {
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        
        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }
}

extension PetSelectHeaderView {
    fileprivate var dropdownEvent: ControlEvent<UITapGestureRecognizer> {
        self.tap.rx.event
    }
}

extension Reactive where Base: PetSelectHeaderView {
    var dropdownEvent: ControlEvent<UITapGestureRecognizer> {
        base.dropdownEvent
    }
}
