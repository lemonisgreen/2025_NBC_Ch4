//
//  ButtonManager.swift
//  SherlDog
//
//  Created by 전원식 on 6/10/25.
//

import UIKit

class ButtonManager: UIButton {
    
    
    init(title: String) {
        super.init(frame: .zero)
        configureUI(title: title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    private func configureUI(title: String){
          
         setTitle(title, for: .normal)
         setTitleColor(.white, for: .normal)
         backgroundColor = UIColor(named: "keycolorPrimary1")
         titleLabel?.font = UIFont(name: "Pretendard-Bold", size: 18)
         layer.cornerRadius = 6
         clipsToBounds = true
        
         self.snp.makeConstraints {
            $0.height.equalTo(52)
        }
    }
      
}
