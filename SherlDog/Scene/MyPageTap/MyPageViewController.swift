//
//  MyPageViewController.swift
//  SherlDog
//
//  Created by 전원식 on 6/24/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class MyPageViewController : UIViewController {
    
    private let disposeBag = DisposeBag()
    let settingButton = ButtonManager(title: "설정")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        configureUI()
        bind()
    }
    
    private func setupUI() {
        [
            settingButton
        ].forEach {
            view.addSubview($0)
        }
    }
    
    private func configureUI() {
        settingButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(100)
            $0.centerX.equalToSuperview()
        }
    }
    
    private func bind() {
        settingButton.rx.tap
            .bind { [weak self] in
                let settingVC = SettingVIewController()
                let backItem = UIBarButtonItem()
                backItem.title = "설정"
                self?.navigationItem.backBarButtonItem = backItem
                self?.navigationController?.navigationBar.titleTextAttributes = [
                    .foregroundColor: UIColor(named: "textPrimary"),
                    .font: UIFont.highlight3
                ]
                self?.navigationController?.navigationBar.tintColor = .textPrimary
                self?.navigationController?.pushViewController(settingVC, animated: true)
            }
            .disposed(by: disposeBag)
    }
}
