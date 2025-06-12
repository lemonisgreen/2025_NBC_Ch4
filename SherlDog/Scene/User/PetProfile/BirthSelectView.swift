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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = .white
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.setValue(UIColor(named: "font1"), forKey: "textColor")
        self.addSubview(datePicker)
        
        
    }
    
    private func configureUI() {
        datePicker.snp.makeConstraints{
            $0.top.equalToSuperview().inset(50)
            $0.leading.trailing.equalToSuperview().inset(20)
            
        }
    }
}
