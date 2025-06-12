//
//  BirthSelectView.swift
//  SherlDog
//
//  Created by JIN LEE on 6/12/25.
//

import UIKit
import SnapKit

class BirthSelectView: UIView {
    
    let birthSelectLabel = UILabel()
    let underLine = UIView()
    let datePicker = UIDatePicker()
    let complateButton = ButtonManager(title: "선택 완료")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.addSubviews([birthSelectLabel,
                          underLine,
                          datePicker,
                          complateButton
                         ])
        
        self.backgroundColor = .white
        
        birthSelectLabel.text = "생년월일을 알려주세요"
        birthSelectLabel.font = .title1
        birthSelectLabel.textColor = .textPrimary
        
        underLine.backgroundColor = .gray200
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels

    }
    
    private func configureUI() {
        birthSelectLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(34 + 16)
            $0.leading.equalToSuperview().inset(16)
        }
        
        underLine.snp.makeConstraints {
            $0.top.equalTo(birthSelectLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(1)
        }
        
        datePicker.snp.makeConstraints{
            $0.top.equalTo(underLine.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        complateButton.snp.makeConstraints {
            $0.top.equalTo(datePicker.snp.bottom).offset(12 + 16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
}
