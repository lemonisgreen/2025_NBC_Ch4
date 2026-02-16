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

class registBreedButton: UIButton {
    
    private let magnifyingGlassIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    
    let breedText = BehaviorRelay<String>(value: "")
    let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init() {
        super.init(frame: .zero)
        setConfig()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bind() {
        breedText
            .bind(to: self.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        breedText
            .map { !$0.isEmpty }
            .subscribe(onNext: { [weak self] isSelected in
                self?.setTitleColor(isSelected ? .textPrimary : .textTertiary, for: .normal)
                self?.magnifyingGlassIcon.isHidden = isSelected
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
        self.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 0)
        self.snp.makeConstraints {
            $0.height.equalTo(44)
        }
        
        magnifyingGlassIcon.tintColor = .textTertiary
        self.addSubview(magnifyingGlassIcon)
        magnifyingGlassIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
    }
}
