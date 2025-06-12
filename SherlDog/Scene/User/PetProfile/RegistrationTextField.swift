//
//  RegistrationTextField.swift
//  SherlDog
//
//  Created by Jin Lee on 6/10/25.
//

import UIKit
import SnapKit

class RegistrationTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(text: String) {
        super.init(frame: .zero)
        self.placeholder = text
        setConfig() //init시 setConfig 메서드 호출
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 인스턴스가 생성될때 초기 설정 값 설정 메서드
    func setConfig() {
        self.backgroundColor = .gray50
        self.font = .body3
        self.textColor = .textPrimary
        self.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        self.leftViewMode = .always
        self.layer.cornerRadius = 6
        self.snp.makeConstraints {
            $0.height.equalTo(44)
        }
    }
}
