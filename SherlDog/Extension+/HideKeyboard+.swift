//
//  HideKeyboard+.swift
//  SherlDog
//
//  Created by JIN LEE on 6/24/25.
//

import UIKit
import RxSwift
import RxCocoa

extension UIViewController {
    func hideKeyboardWhenTappedAroundRx(disposeBag: DisposeBag) {
        let tap = UITapGestureRecognizer()
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        tap.rx.event
            .bind { [weak self] _ in
                self?.view.endEditing(true)
            }
            .disposed(by: disposeBag)
    }
}
