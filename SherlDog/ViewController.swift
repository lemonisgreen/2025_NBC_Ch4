//
//  ViewController.swift
//  SherlDog
//
//  Created by 최영락 on 6/4/25.
//

import UIKit

class ViewController: UIViewController {
    
    let splashView = SplashView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUi()
    }
    
    func setupUi() {
        view.addSubview(splashView)
        view.bringSubviewToFront(splashView)
        splashView.frame = view.bounds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.dismissSplashView()
        }
    }
}



extension ViewController {
    func dismissSplashView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.splashView.alpha = 0
        }) { _ in
            self.splashView.removeFromSuperview()
        }
    }
}
