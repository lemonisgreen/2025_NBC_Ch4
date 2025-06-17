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
class CreateAssistantProfileViewController: UIViewController { // todo: Merge 받고 PictureRequestView 호출 시 뷰모델 주입
    
    private let avatarViewModel = SelectAvatarViewModel()
    private let cameraViewModel = CameraViewModel()
    private let disposeBag = DisposeBag()
    
    private let navigationBackButton = UIButton()
    private let navigationTitleLabel = UILabel()
    private let profileImageView = UIImageView()
    private let profileCameraButtonImageView = UIImageView()
    private let profileimageSetbutton = UIButton()
    private let separatorView = UIView()
    private let nickNameLabel = UILabel()
    private let nicknameTextField = UITextField()
    private let nickNameConstraintsLabel = UILabel()
    private let nickNameSeparatorAlertImage = UIImageView()
    private let nickNameSeparatorAlert = UILabel()
    private let introduceLabel = UILabel()
    private let introduceTextView = UITextView()
    private let introduceConstraintsLabel = UILabel()
    private let nextButton = ButtonManager(title: "다음")
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
        self.avatarViewModel.output.completeSelect
            .subscribe(onNext: { [weak self] imageName in
                guard let self else { return }
                self.profileImageView.image = UIImage(named: imageName)
            })
            .disposed(by: disposeBag)
        
        self.cameraViewModel.output.capturedImage
            .subscribe(onNext: { [weak self] image in
                guard let self, let image else { return }
                self.profileImageView.image = image
            })
            .disposed(by: disposeBag)
        
        self.nicknameTextField.rx.text
            .subscribe(onNext: { [weak self] text in
                guard let self, let text else { return }
                
                self.nickNameConstraintsLabel.text = "\(text.count) / 12자"
                
                if text.count > 12 {
                    let diff = text.count - 12
                    self.nicknameTextField.text?.removeLast(diff)
                    self.nickNameConstraintsLabel.text = "12 / 12자"
                }
                
                if text.contains(" ") {
                    self.nickNameSeparatorAlert.isHidden = false
                    self.nickNameSeparatorAlertImage.isHidden = false
                } else {
                    self.nickNameSeparatorAlert.isHidden = true
                    self.nickNameSeparatorAlertImage.isHidden = true
                }
            })
            .disposed(by: disposeBag)
        
        self.introduceTextView.rx.text
            .subscribe(onNext: { [weak self] text in
                guard let self, let text else { return }
                
                if text.count > 150 {
                    let diff = text.count - 150
                    self.introduceTextView.text.removeLast(diff)
                }
                
                self.introduceConstraintsLabel.text = "\(text.count) / 150자"
                
                if text.count > 0 {
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
                
                let requestView = UINavigationController(rootViewController: PictureUploadRequestView(viewModel: pictureViewModel, cameraViewModel: cameraViewModel))
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
            separatorView,
            nickNameLabel,
            nicknameTextField,
            nickNameSeparatorAlertImage,
            nickNameSeparatorAlert,
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
        navigationTitleLabel.textColor = .textPrimary
        navigationTitleLabel.snp.makeConstraints { $0.width.equalTo(UIScreen.main.bounds.width * (4 / 5)) }
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationBackButton)
        self.navigationItem.titleView = navigationTitleLabel
      
        profileImageView.image = .petProfile
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.clipsToBounds = true
        profileImageView.tintColor = .gray300
        
        profileCameraButtonImageView.image = .profileCamera
        profileCameraButtonImageView.contentMode = .scaleAspectFit
        
        separatorView.backgroundColor = .gray200
        
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
        
        nickNameSeparatorAlertImage.contentMode = .scaleAspectFit
        nickNameSeparatorAlertImage.image = .alertMark
        
        nickNameSeparatorAlert.text = "공백 없이 입력해 주세요"
        nickNameSeparatorAlert.font = .alert2
        nickNameSeparatorAlert.textColor = .textAlert
        
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
    }
    
    private func configureUI() {
        let profileButtonSize: CGFloat = 140
        let profileImageInset: CGFloat = 8
        let profileCameraButtonSize: CGFloat = 44
        
        profileImageView.layer.cornerRadius = (profileButtonSize - profileImageInset) / 2
        
        profileimageSetbutton.snp.makeConstraints {
            $0.height.width.equalTo(profileButtonSize)
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.centerX.equalToSuperview()
        }
        
        profileImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.trailing.bottom.equalToSuperview().inset(profileImageInset)
        }
        
        profileCameraButtonImageView.snp.makeConstraints {
            $0.height.width.equalTo(profileCameraButtonSize)
            $0.trailing.bottom.equalToSuperview().inset(4)
        }
        
        separatorView.snp.makeConstraints {
            $0.top.equalTo(profileimageSetbutton.snp.bottom).offset(20)
            $0.height.equalTo(1)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        nickNameLabel.snp.makeConstraints {
            $0.top.equalTo(separatorView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().inset(16)
        }
        
        nicknameTextField.snp.makeConstraints {
            $0.height.equalTo(44)
            $0.top.equalTo(nickNameLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        nickNameConstraintsLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
        
        nickNameSeparatorAlertImage.snp.makeConstraints {
            $0.height.width.equalTo(14)
            $0.top.equalTo(nicknameTextField.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(16)
        }
        
        nickNameSeparatorAlert.snp.makeConstraints {
            $0.top.equalTo(nickNameSeparatorAlertImage)
            $0.leading.equalTo(nickNameSeparatorAlertImage.snp.trailing).offset(8)
        }
        
        introduceLabel.snp.makeConstraints {
            $0.top.equalTo(nickNameSeparatorAlertImage.snp.bottom).offset(8)
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
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
}
