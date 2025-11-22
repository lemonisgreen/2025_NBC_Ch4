//
//  ReportReasonBottomSheetViewController.swift
//  SherlDog
//
//  Created by Jin Lee on 11/13/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ReportReasonBottomSheetViewController: UIViewController {
    enum Reason: String, CaseIterable {
        case badLanguage   = "욕설 사용"
        case ad            = "광고성 글"
        case sexual        = "선정적 내용"
        case inappropriate = "부적절한 글"
        case badManner     = "비매너 유저"
        case etc           = "기타"
    }
    
    let selectedReason = PublishSubject<Reason>()
    private let disposeBag = DisposeBag()
    
    private let containerView = UIView()
    private let stackView = UIStackView()
    private let cancelButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func bind() {
        let backgroundTap = UITapGestureRecognizer()
        view.addGestureRecognizer(backgroundTap)
        
        backgroundTap.rx.event
            .bind { [weak self] _ in
                self?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .bind { [weak self] in
                self?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    func makeReasonButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.textAlert, for: .normal)
        button.titleLabel?.font = .title3
        button.backgroundColor = .white
        button.contentEdgeInsets = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
        
        return button
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 24
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        
        stackView.axis = .vertical
        stackView.spacing = 0
        //stackView.distribution = .fillEqually
        
        let topSpacer = UIView()
        topSpacer.snp.makeConstraints { $0.height.equalTo(4) }
        stackView.addArrangedSubview(topSpacer)
        
        Reason.allCases.forEach { reason in
            let button = makeReasonButton(title: reason.rawValue)
            
            button.rx.tap
                .bind { [weak self] in
                    guard let self else { return }
                    self.selectedReason.onNext(reason)
                    self.dismiss(animated: true)
                }
                .disposed(by: disposeBag)
            
            stackView.addArrangedSubview(button)
            
            let separator = UIView()
            separator.backgroundColor = UIColor.systemGray5
            button.addSubview(separator)
            separator.snp.makeConstraints {
                $0.height.equalTo(0.5)
                $0.leading.trailing.equalToSuperview().inset(16)
                $0.bottom.equalToSuperview()
            }
        }
        
        cancelButton.setTitle("취소", for: .normal)
        cancelButton.setTitleColor(.gray900, for: .normal)
        cancelButton.titleLabel?.font = .title3
        cancelButton.backgroundColor = .white
        
        view.addSubview(containerView)
        containerView.addSubview(stackView)
        containerView.addSubview(cancelButton)
    }
    
    private func configureUI() {
        containerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
        stackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.trailing.equalToSuperview()
        }
        
        cancelButton.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(56)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
}
