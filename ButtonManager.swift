//
//  ButtonManager.swift
//  SherlDog
//
//  Created by 전원식 on 6/10/25.
//

import UIKit
import SnapKit

class ButtonManager: UIButton {

    init(title: String, backgroundColor: UIColor = UIColor(named: "keycolorPrimary1") ?? .systemBlue, titleColor: UIColor = .white, width: CGFloat = 52) {
        super.init(frame: .zero)
        configureUI(title: title, backgroundColor: backgroundColor, titleColor: titleColor, width: width)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI(title: String, backgroundColor: UIColor, titleColor: UIColor, width: CGFloat){
          
         setTitle(title, for: .normal)
         setTitleColor(titleColor, for: .normal)
         self.backgroundColor = backgroundColor
         titleLabel?.font = UIFont(name: "Pretendard-Bold", size: 18)
         layer.cornerRadius = 6
         clipsToBounds = true
        
         self.snp.makeConstraints {
            $0.height.equalTo(52)
            $0.width.equalTo(width)
        }
    }
      
}
