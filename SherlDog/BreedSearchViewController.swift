//
//  BreedSearchViewController.swift
//  SherlDog
//
//  Created by 최영락 on 6/10/25.
//

import UIKit
import SnapKit

class BreedSearchViewController: UIViewController {
    
    // MARK: - Constants
    private struct Constants {
        static let titleFontSize: CGFloat = 20
        static let searchFieldHeight: CGFloat = 40
        static let closeButtonSize: CGFloat = 24
        static let imageSize: CGFloat = 80
        static let padding: CGFloat = 20
    }
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "견종 선택하기"
        label.font = UIFont.boldSystemFont(ofSize: Constants.titleFontSize)
        label.textColor = .black
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .black
        return button
    }()
    
    private let searchTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "검색"
        tf.backgroundColor = .white
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor(hex: "C7C7CC").cgColor
        tf.layer.cornerRadius = 8
        tf.font = .systemFont(ofSize: 16)
        return tf
    }()
    
    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "sherlDog")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGray3
        iv.alpha = 1
        return iv
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "어떤 견종을 찾으시나요?"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup
    private func setupUI() {
        searchTextField.setLeftPaddingIcon(systemName: "magnifyingglass")
        
        [titleLabel, closeButton, searchTextField, emptyImageView, emptyLabel].forEach {
            view.addSubview($0)
        }
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.padding)
            $0.leading.equalToSuperview().inset(Constants.padding)
        }
        
        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(Constants.padding)
            $0.size.equalTo(Constants.closeButtonSize)
        }
        
        searchTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(Constants.padding)
            $0.height.equalTo(Constants.searchFieldHeight)
        }
        
        emptyImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(searchTextField.snp.bottom).offset(80)
            $0.size.equalTo(Constants.imageSize)
        }
        
        emptyLabel.snp.makeConstraints {
            $0.top.equalTo(emptyImageView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITextField Extension
extension UITextField {
    func setLeftPaddingIcon(systemName: String) {
        let icon = UIImageView(image: UIImage(systemName: systemName))
        icon.tintColor = .systemGray
        icon.contentMode = .scaleAspectFit
        
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        icon.frame = CGRect(x: 8, y: 8, width: 20, height: 20)
        container.addSubview(icon)
        
        self.leftView = container
        self.leftViewMode = .always
    }
}
