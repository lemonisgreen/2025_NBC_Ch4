//
//  PetProfileViewController.swift
//  SherlDog
//
//  Created by 최영락 on 6/5/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class PetProfileViewController: UIViewController {

    // MARK: - Properties
    private let disposeBag = DisposeBag()

    // MARK: - UI Components
    private let profileAddButton = UIButton()
    private let dogImageView = UIImageView()
    private let infoLabel = UILabel()
    private let nextButton = UIButton()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        configureUI()
        bindUI()
    }

    // MARK: - UI Setup
    private func setupNavigationBar() {
        navigationItem.title = "멍탐정 프로필 입력하기"
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func setupUI() {
        view.backgroundColor = UIColor.keycolorBackground

        profileAddButton.backgroundColor = UIColor.gray100
        profileAddButton.layer.cornerRadius = 16
        profileAddButton.layer.borderWidth = 1
        profileAddButton.layer.borderColor = UIColor.textTertiary.cgColor

        dogImageView.image = UIImage(named: "sherlDog")
        dogImageView.contentMode = .scaleAspectFit

        infoLabel.text = "멍탐정을 등록해주세요!"
        infoLabel.textColor = UIColor.textDisabled
        infoLabel.font = .systemFont(ofSize: 16)
        infoLabel.textAlignment = .center

        nextButton.setTitle("다음", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = UIColor.textDisabled
        nextButton.layer.cornerRadius = 10
        nextButton.isEnabled = false

        let buttonStack = makeProfileButtonStack()
        profileAddButton.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { $0.center.equalToSuperview() }

        [profileAddButton, dogImageView, infoLabel, nextButton].forEach {
            view.addSubview($0)
        }
    }

    private func configureUI() {
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

    private func bindUI() {
        profileAddButton.rx.tap
            .bind { [weak self] in self?.presentBreedSearch() }
            .disposed(by: disposeBag)
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

    // MARK: - Navigation
    private func presentBreedSearch() {
        let breedSearchVC = BreedSearchViewController()
        let nav = UINavigationController(rootViewController: breedSearchVC)
        nav.modalPresentationStyle = .automatic
        present(nav, animated: true)
    }
}
