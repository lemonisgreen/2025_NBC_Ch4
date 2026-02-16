//
//  RegistrationSearchButton.swift
//  SherlDog
//
//  Created by Jin Lee on 6/10/25.
//

import UIKit
import SnapKit
import RxSwift
import RxRelay

class registBirthdayButton: UIButton {
    
    let dateText = BehaviorRelay<String>(value: "YYYY-MM-DD (n세)")
    let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(title: String) {
        super.init(frame: .zero)
        self.setTitle(title, for: .normal)
        setConfig()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bind() {
        dateText
            .bind(to: self.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        dateText
            .map { $0 != "YYYY-MM-DD (n세)" }
            .subscribe(onNext: { [weak self] isSelected in
                self?.setTitleColor(isSelected ? .textPrimary : .textTertiary, for: .normal)
            })
            .disposed(by: disposeBag)
    }
    
    func setConfig() {
        self.backgroundColor = .textInverse
        self.setTitleColor(.textDisabled, for: .normal)
        self.contentHorizontalAlignment = .leading
        self.titleLabel?.font = .body3
        self.layer.borderColor = UIColor.gray200.cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 6
        self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        self.snp.makeConstraints {
            $0.height.equalTo(44)
        }
    }
}
