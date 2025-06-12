//
//  ViewController.swift
//  SherlDog
//
//  Created by 최영락 on 6/4/25.
//

import UIKit

class ViewController: UIViewController {
    
    let datepicker = BirthSelectView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(datepicker)
        datepicker.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
        }
    }
}


