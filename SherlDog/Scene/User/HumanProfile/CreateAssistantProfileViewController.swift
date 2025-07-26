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
    
    private var selectedImage: UIImage?
    private let avatarViewModel = SelectAvatarViewModel()
    private let cameraViewModel = CameraViewModel()
    private let viewModel = HumanProfileViewModel()
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
        self.hideKeyboardWhenTappedAroundRx(disposeBag: disposeBag)
        
        setupUI()
        configureUI()
        
        if viewModel.isEditMode.value {
               setInitialUIValues()
           }
        
        bind()
        bindViewModel()
    }
}

// MARK: - Method
extension CreateAssistantProfileViewController {
    
    func configure(with profile: HumanProfileModel) {
        viewModel.setEditMode(with: profile)
        
        DispatchQueue.main.async { [weak self] in
              if self?.isViewLoaded == true {
                  self?.setInitialUIValues()
              }
          }
    }
    
    private func setInitialUIValues() {
        // 텍스트 설정
        nicknameTextField.text = viewModel.nickname.value
        introduceTextView.text = viewModel.introduce.value
   
        // 글자 수 업데이트
        nickNameConstraintsLabel.text = "\(viewModel.nickname.value.count) / 12자"
        introduceConstraintsLabel.text = "\(viewModel.introduce.value.count) / 150자"
        
        // 이미지 설정
        if let image = viewModel.image.value {
            profileImageView.image = image
        }
    
        nicknameTextField.sendActions(for: .editingChanged)
        
        if let delegate = introduceTextView.delegate {
            delegate.textViewDidChange?(introduceTextView)
        }
        
        loadProfileImage()
    }
    
    private func loadProfileImage() {
        guard case .edit(let profile) = viewModel.currentMode else { return }
        
        FirebaseImageManager.shared.downloadImage(
            userId: viewModel.userId ?? "",
            type: .assistant
        ) { [weak self] image in
            DispatchQueue.main.async {
                if let image = image {
                    self?.selectedImage = image
                    self?.profileImageView.image = image
                    self?.cameraViewModel.output.capturedImage.accept(image)
                }
            }
        }
    }
    
    private func bind() {
        Observable.combineLatest(
            self.cameraViewModel.output.capturedImage,
            self.avatarViewModel.output.selectedAvatar,
            self.nicknameTextField.rx.text,
            self.introduceTextView.rx.text
        )
        .subscribe(onNext: { [weak self] image, avatar, nickName, introduce in
            if image != nil || avatar != nil,
               nickName != "",
               introduce != "" {
                if let nickName, nickName.contains(" ") {
                    self?.nextButton.isEnabled = false
                    
                } else {
                    self?.nextButton.isEnabled = true
                    
                }
                
            } else {
                self?.nextButton.isEnabled = false
            }
        })
        .disposed(by: disposeBag)
        
        navigationBackButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        self.avatarViewModel.output.completeSelect
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let imageName = self.avatarViewModel.output.icon.value
                
                self.profileImageView.image = UIImage(named: imageName)
                self.profileImageView.contentMode = .scaleAspectFit
            })
            .disposed(by: disposeBag)
        
        self.cameraViewModel.output.capturedImage
            .subscribe(onNext: { [weak self] image in
                guard let self, let image else { return }
                self.profileImageView.image = image
                self.profileImageView.contentMode = .scaleAspectFill
            })
            .disposed(by: disposeBag)
        
        self.nicknameTextField.rx.text
            .subscribe(onNext: { [weak self] text in
                guard let self, var text else { return }
                
                if text.count > 12 {
                    let diff = text.count - 12
                    text.removeLast(diff)
                    
                    self.nicknameTextField.text = text
                }
                
                self.nickNameConstraintsLabel.text = "\(text.count) / 12자"
                
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
                pictureViewModel.input.accept(.sender(.pictureRequestForAssistant))
                
                let requestView = UINavigationController(rootViewController: PictureUploadRequestViewController(viewModel: pictureViewModel, cameraViewModel: cameraViewModel, avatarViewModel: avatarViewModel))
                requestView.modalPresentationStyle = .pageSheet
                
                if let sheet = requestView.sheetPresentationController {
                    sheet.detents = [.custom { _ in 400 }]
                    sheet.selectedDetentIdentifier = .medium
                    sheet.prefersGrabberVisible = true
                    sheet.preferredCornerRadius = 20
                }
                
                self.present(requestView, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindViewModel() {
        // 네비게이션 타이틀 변경
        viewModel.navigationTitle
            .bind(to: navigationTitleLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 닉네임 입력
        nicknameTextField.rx.text.orEmpty
            .bind(to: viewModel.nickname)
            .disposed(by: disposeBag)
        
        // 소개글 입력
        introduceTextView.rx.text.orEmpty
            .bind(to: viewModel.introduce)
            .disposed(by: disposeBag)
        
        // 카메라로 촬영한 이미지 바인딩
        cameraViewModel.output.capturedImage
            .compactMap { $0 }
            .bind(to: viewModel.image)
            .disposed(by: disposeBag)
        
        // 아바타 선택한 이미지 바인딩
        avatarViewModel.output.completeSelect
            .compactMap { [weak self] in
                guard let self else { return nil }
                
                let imageName = self.avatarViewModel.output.icon.value
                return UIImage(named: imageName)
            }
            .bind(to: viewModel.image)
            .disposed(by: disposeBag)
        
        // 뷰모델 이미지 변경을 profileImageView에 바인딩
        viewModel.image
            .asObservable()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] image in
                if let image = image {
                    self?.profileImageView.image = image
                    self?.profileImageView.contentMode = .scaleAspectFill
                }
            })
            .disposed(by: disposeBag)
        
        // 로딩 상태 처리
        viewModel.isLoading
            .subscribe(onNext: { [weak self] isLoading in
                self?.nextButton.isEnabled = !isLoading
                // 로딩 인디케이터가 있다면 여기서 처리
            })
            .disposed(by: disposeBag)
        
        // 저장 결과 처리
        viewModel.saveResult
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success:
                    // 수정모드일 때 저장 성공시 뒤로가기
                    if self?.viewModel.isEditMode.value == true {
                        self?.navigationController?.popViewController(animated: true)
                    } else {
                        // 저장 성공 시 메인 화면으로 이동
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let delegate = windowScene.delegate as? SceneDelegate,
                           let window = delegate.window {
                            let mainView = BottomTabBarController()
                            window.rootViewController = mainView
                            window.makeKeyAndVisible()
                        }
                    }
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
        
        // 다음 버튼
        nextButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.uploadAndSaveProfile()
            })
            .disposed(by: disposeBag)
        
        //수정모드일 때 다음 버튼 타이틀 변경
        viewModel.nextButtonTitle
            .bind(to: nextButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        viewModel.isSaveEnabled
            .bind(to: nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
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
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .keycolorBackground
        navigationBarAppearance.shadowColor = .clear
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationBackButton)
        self.navigationItem.titleView = navigationTitleLabel
        self.navigationItem.standardAppearance = navigationBarAppearance
        self.navigationItem.scrollEdgeAppearance = navigationBarAppearance
        
        profileImageView.image = .petProfile
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.layer.borderColor = UIColor.gray100.cgColor
        profileImageView.layer.borderWidth = 1
        profileImageView.clipsToBounds = true
        
        profileCameraButtonImageView.image = .profileCamera
        profileCameraButtonImageView.contentMode = .scaleAspectFit
        
        separatorView.backgroundColor = .gray200
        
        nicknameTextField.placeholder = "탐정님이 부를 닉네임을 입력해주세요!"
        nicknameTextField.backgroundColor = .gray50
        nicknameTextField.layer.cornerRadius = 6
        nicknameTextField.leftView = UIView(frame: .init(x: 0, y: 0, width: 12, height: 0))
        nicknameTextField.leftViewMode = .always
        nicknameTextField.textColor = .textPrimary
        
        nickNameLabel.text = "닉네임"
        nickNameLabel.font = .body1
        nickNameLabel.textColor = .textPrimary
        
        nickNameConstraintsLabel.text = "0 / 12자"
        nickNameConstraintsLabel.font = .alert2
        nickNameConstraintsLabel.textColor = .gray300
        
        nickNameSeparatorAlertImage.contentMode = .scaleAspectFit
        nickNameSeparatorAlertImage.image = .alertMark
        nickNameSeparatorAlertImage.isHidden = true
        
        nickNameSeparatorAlert.text = "공백 없이 입력해 주세요"
        nickNameSeparatorAlert.font = .alert2
        nickNameSeparatorAlert.textColor = .textAlert
        nickNameSeparatorAlert.isHidden = true
        
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
        introduceTextView.textColor = .textPrimary
        
        introduceConstraintsLabel.text = "0 / 150자"
        introduceConstraintsLabel.font = .alert2
        introduceConstraintsLabel.textColor = .gray400
        
        self.nextButton.isEnabled = false
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
