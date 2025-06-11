//
//  ViewController.swift
//  SherlDog
//
//  Created by 최영락 on 6/4/25.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vc = UINavigationController(rootViewController: PictureUploadRequestView(viewModel: PictureUploadRequestViewModel()))
        
        vc.modalPresentationStyle = .pageSheet
        
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.selectedDetentIdentifier = .medium
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 32
        }
        
        self.present(vc, animated: true)
    }
}
