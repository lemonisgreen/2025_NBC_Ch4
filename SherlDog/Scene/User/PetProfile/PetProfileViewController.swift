//
//  PetProfileViewController.swift
//  SherlDog
//
//  Created by 최영락 on 6/5/25.
//

import UIKit
import SnapKit

class PetProfileViewController: UIViewController {

    // MARK: - 컴포넌트
    private let profileAddButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.gray100
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.textTertiary.cgColor
        return button
    }()

    private let dogImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "sherlDog") // 자산에 등록 필요
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "멍탐정을 등록해주세요!"
        label.textColor = UIColor.textDisabled
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()

    private let nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("다음", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.textDisabled
        button.layer.cornerRadius = 10
        button.isEnabled = false
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        navigationItem.title = "멍탐정 프로필 입력하기"
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func setupUI() {
        view.backgroundColor = UIColor.keycolorBackground

        let buttonStack = makeProfileButtonStack()
        profileAddButton.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { $0.center.equalToSuperview() }
        profileAddButton.addTarget(self, action: #selector(profileAddButtonTapped), for: .touchUpInside)

        [profileAddButton, dogImageView, infoLabel, nextButton].forEach {
            view.addSubview($0)
        }
    }

    private func setupConstraints() {
        profileAddButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(208)
        }

        dogImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(20)
            $0.size.equalTo(80)
        }

        infoLabel.snp.makeConstraints {
            $0.top.equalTo(dogImageView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }

        nextButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(54)
        }
    }

    // MARK: - Factory
    private func makeProfileButtonStack() -> UIStackView {
        let circleView = UIView()
        circleView.layer.cornerRadius = 30
        circleView.layer.borderWidth = 2
        circleView.layer.borderColor = UIColor.textTertiary.cgColor

        let plusImage = UIImageView(image: UIImage(systemName: "plus"))
        plusImage.tintColor = UIColor.textTertiary
        plusImage.contentMode = .scaleAspectFit
        circleView.addSubview(plusImage)
        plusImage.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(24) }
        circleView.snp.makeConstraints { $0.size.equalTo(60) }

        let titleLabel = UILabel()
        titleLabel.text = "프로필 추가하기"
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.textTertiary

        let stack = UIStackView(arrangedSubviews: [circleView, titleLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        return stack
    }

    // MARK: - Actions
    @objc private func profileAddButtonTapped() {
        let breedSearchVC = BreedSearchViewController()
        let nav = UINavigationController(rootViewController: breedSearchVC)
        nav.modalPresentationStyle = .automatic
        present(nav, animated: true)
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
