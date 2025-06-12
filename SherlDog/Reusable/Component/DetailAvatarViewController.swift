//
//  DetailAvatarViewController.swift
//  SherlDog
//
//  Created by 최규현 on 6/11/25.
//

import RxSwift
import RxCocoa
import UIKit
import SnapKit

// MARK: - DetailAvatarViewController
class DetailAvatarViewController: UIViewController {
    
    private let viewModel: SelectAvatarViewModel
    
    // MARK: - Initialize
    init(viewModel: SelectAvatarViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Lifecycle
extension DetailAvatarViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
    }
    
}

// MARK: - Method
extension DetailAvatarViewController {
    
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    private func configureUI() {
        
    }
    
}
