//
//  CreateAssistantProfileViewController.swift
//  SherlDog
//
//  Created by 최규현 on 6/10/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - AssistantProfileViewController
class CreateAssistantProfileViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private let navigationBackButton = UIButton()
    private let navigationTitleLabel = UILabel()
    private let profileImageView = UIImageView()
    private let profileCameraButtonImageView = UIImageView()
    private let profileimageSetbutton = UIButton()
    private let nickNameLabel = UILabel()
    private let nicknameTextField = UITextField()
    private let nickNameConstraintsLabel = UILabel()
    private let introduceLabel = UILabel()
    private let introduceTextView = UITextView()
    private let introduceConstraintsLabel = UILabel()
    private let nextButton = UIButton()
    private let textViewPlaceholder = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        bind()
    }
}

// MARK: - Method
extension CreateAssistantProfileViewController {
    
    private func bind() {
        self.nicknameTextField.rx.text
            .subscribe(onNext: { [weak self] _ in
                guard let self,
                let text = self.nicknameTextField.text else { return }
                
                self.nickNameConstraintsLabel.text = "\(text.count) / 12자"
                
                if text.count > 12 {
                    let diff = text.count - 12
                    self.nicknameTextField.text?.removeLast(diff)
                    self.nickNameConstraintsLabel.text = "12 / 12자"
                }
            })
            .disposed(by: disposeBag)
        
        self.introduceTextView.rx.didChange
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                
                self.introduceConstraintsLabel.text = "\(self.introduceTextView.text.count) / 150자"
                
                if self.introduceTextView.text.count > 150 {
                    let diff = self.introduceTextView.text.count - 150
                    self.introduceTextView.text.removeLast(diff)
                    self.introduceConstraintsLabel.text = "150 / 150자"
                }
                
                if self.introduceTextView.text.count > 0 {
                    self.textViewPlaceholder.isHidden = true
                } else {
                    self.textViewPlaceholder.isHidden = false
                }
            })
            .disposed(by: disposeBag)
        
        self.profileimageSetbutton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                let pictureViewModel = PictureUploadRequestViewModel()
                pictureViewModel.input.accept(.sender(.pictureRequestWithIcon))
                let requestView = UINavigationController(rootViewController: PictureUploadRequestView(viewModel: pictureViewModel))
                requestView.modalPresentationStyle = .pageSheet
                
                if let sheet = requestView.sheetPresentationController {
                    sheet.detents = [.medium()]
                    sheet.selectedDetentIdentifier = .medium
                    sheet.prefersGrabberVisible = true
                    sheet.preferredCornerRadius = 32
                }
                self.present(requestView, animated: true)
            })
            .disposed(by: disposeBag)
        
        self.nextButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                let mainVC = MainViewController()
                self?.navigationController?.pushViewController(mainVC, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        view.backgroundColor = .keycolorBackground
        
        profileimageSetbutton.addSubviews([profileImageView, profileCameraButtonImageView])
        nicknameTextField.addSubview(nickNameConstraintsLabel)
        introduceTextView.addSubview(textViewPlaceholder)
        
        view.addSubviews([
            profileimageSetbutton,
            nickNameLabel,
            nicknameTextField,
            introduceLabel,
            introduceTextView,
            introduceConstraintsLabel,
            nextButton,
        ])
        
        navigationBackButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        navigationTitleLabel.text = "조수 프로필 입력하기"
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.snp.makeConstraints { $0.width.equalTo(UIScreen.main.bounds.width * (4 / 5)) }
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationBackButton)
        self.navigationItem.titleView = navigationTitleLabel
        
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.tintColor = .gray300
        
        profileCameraButtonImageView.image = UIImage(systemName: "camera.circle.fill")
        profileCameraButtonImageView.contentMode = .scaleAspectFit
        profileCameraButtonImageView.tintColor = .gray600
        
        nicknameTextField.placeholder = "탐정님이 부를 닉네임을 입력해주세요!"
        nicknameTextField.backgroundColor = .gray50
        nicknameTextField.layer.cornerRadius = 6
        nicknameTextField.leftView = UIView(frame: .init(x: 0, y: 0, width: 12, height: 0))
        nicknameTextField.leftViewMode = .always
        
        nickNameLabel.text = "닉네임"
        nickNameLabel.font = .body1
        nickNameLabel.textColor = .textPrimary
        
        nickNameConstraintsLabel.text = "0 / 12자"
        nickNameConstraintsLabel.font = .alert2
        nickNameConstraintsLabel.textColor = .gray300
        
        introduceLabel.text = "자기소개"
        introduceLabel.font = .body1
        introduceLabel.textColor = .textPrimary
        
        textViewPlaceholder.text = "간단한 자기소개로 탐정 팀에 합류해요"
        textViewPlaceholder.font = .body3
        textViewPlaceholder.textColor = .textDisabled
        
        introduceTextView.font = .body3
        introduceTextView.backgroundColor = .gray50
        introduceTextView.layer.cornerRadius = 6
        introduceTextView.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        
        introduceConstraintsLabel.text = "0 / 150자"
        introduceConstraintsLabel.font = .alert2
        introduceConstraintsLabel.textColor = .gray400
        
        nextButton.setTitle("다음", for: .normal)
        nextButton.backgroundColor = .keycolorPrimary3
        nextButton.titleLabel?.font = .highlight4
        nextButton.titleLabel?.textColor = .textInverse
        nextButton.layer.cornerRadius = 6
        nextButton.clipsToBounds = true
    }
    
    private func configureUI() {
        let profileButtonLeadingInset: CGFloat = 117.5
        
        profileimageSetbutton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.leading.trailing.equalToSuperview().inset(profileButtonLeadingInset)
            // 다른 기기 대응을 위해 계산한 값입니다.
            $0.height.equalTo(UIScreen.main.bounds.width - (profileButtonLeadingInset * 2))
        }
        
        profileImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.trailing.bottom.equalToSuperview().inset(8)
        }
        
        profileCameraButtonImageView.snp.makeConstraints {
            // 다른 기기 대응을 위해 mulptipliedBy로 크기 잡았습니다. 와이어프레임에서 계산해봤을 때 3.1818... 나오길래 3.18로 잘랐습니다.
            $0.height.width.equalTo(profileimageSetbutton.snp.height).multipliedBy(1.0 / 3.18)
            $0.trailing.bottom.equalToSuperview().inset(4)
        }
        
        nickNameLabel.snp.makeConstraints {
            $0.top.equalTo(profileimageSetbutton.snp.bottom).offset(41)
            $0.leading.equalToSuperview().inset(16)
        }
        
        nicknameTextField.snp.makeConstraints {
            $0.height.equalTo(32)
            $0.top.equalTo(nickNameLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        nickNameConstraintsLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
        
        introduceLabel.snp.makeConstraints {
            $0.top.equalTo(nicknameTextField.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
        }
        
        introduceTextView.snp.makeConstraints {
            $0.height.equalTo(180)
            $0.top.equalTo(introduceLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        textViewPlaceholder.snp.makeConstraints {
            $0.leading.top.equalToSuperview().inset(12)
        }
        
        introduceConstraintsLabel.snp.makeConstraints {
            $0.bottom.trailing.equalTo(introduceTextView).offset(-12)
        }
        
        nextButton.snp.makeConstraints {
            $0.height.equalTo(52)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
}
