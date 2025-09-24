//
//  SplashViewController.swift
//  SherlDog
//
//  Created by JIN LEE on 9/16/25.
//

import UIKit
import SnapKit

class SplashViewController: UIViewController {
    var onSplashEnd: (() -> Void)?
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "Logo")
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.onSplashEnd?()
        }
    }
    
    private func setUpUI() {
        view.addSubview(logoImageView)
        view.backgroundColor = .keycolorBackground

        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(250)
            make.height.equalTo(250)
        }
    }
}
