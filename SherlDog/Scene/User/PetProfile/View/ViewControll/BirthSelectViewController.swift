//
//  BirthSelectView.swift
//  SherlDog
//
//  Created by JIN LEE on 6/12/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class BirthSelectViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    let selectedDate = PublishSubject<Date>()
    
    let birthSelectLabel = UILabel()
    let underLine = UIView()
    let datePicker = UIDatePicker()
    let completeButton = ButtonFactory.makeButton(type: .main, title: "선택 완료")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureUI()
        bind()
    }
    
    func bind() {
        self.completeButton.rx.tap
            .map { [weak self] in self?.datePicker.date ?? Date() }
            .subscribe(onNext: { [weak self] date in
                self?.selectedDate.onNext(date)
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        view.addSubviews([birthSelectLabel,
                          underLine,
                          datePicker,
                          completeButton
                         ])
        
        view.backgroundColor = .white
        
        birthSelectLabel.text = "생년월일을 알려주세요"
        birthSelectLabel.font = .title1
        birthSelectLabel.textColor = .textPrimary
        
        underLine.backgroundColor = .gray200
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.setValue(UIColor(named: "textPrimary"), forKeyPath: "textColor")
        datePicker.maximumDate = Date()
    }
    
    private func configureUI() {
        birthSelectLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(28)
            $0.leading.equalToSuperview().inset(16)
        }
        
        underLine.snp.makeConstraints {
            $0.top.equalTo(birthSelectLabel.snp.bottom).offset(18)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(1)
        }
        
        datePicker.snp.makeConstraints{
            $0.top.equalTo(underLine.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        completeButton.snp.makeConstraints {
            $0.top.equalTo(datePicker.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
}
