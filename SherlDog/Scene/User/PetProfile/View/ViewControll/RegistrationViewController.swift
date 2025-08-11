//
//  RegistrationViewController.swift
//  SherlDog
//
//  Created by Jin Lee on 6/10/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Firebase
import FirebaseStorage
import Kingfisher

class RegistrationViewController: UIViewController {

    enum Mode {
        case add
        case edit(PetProfile)
    }

    private var mode: Mode = .add
    
    private let cameraViewModel = CameraViewModel()
    private let viewModel = RegistrationViewModel()
    
    var onProfileAdded: ((String) -> Void)?
    let profileUpdateSubject = PublishSubject<PetProfile>()
    let disposeBag = DisposeBag()
    
    private var selectedImage: UIImage?

    private let registrationLabel = UILabel()
    private let registrationButton = UIButton()
    private let registrationStackView = UIStackView()
    private let topUnderLine = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let registImage = UIButton()
    private let registImageStamp = UIImageView()
    private let registedProfileImage = UIImageView()
    private let registImageShadow = UIImageView()
    private let registNameLabel = UILabel()
    private let registNameCountLabel = UILabel()
    private let registNameAlertStackView = UIStackView()
    private let registNameAlertImage = UIImageView()
    private let registNameAlertLabel = UILabel()
    private let registName = RegistrationTextField(text: "이름을 입력하세요")
    private let registBreedLabel = UILabel()
    private let registBreed = registBreedButton()
    private let underLine = UIView()
    private let registSizeLabel = UILabel()
    private let registSizeSmallIcon = UIImageView()
    private let registSizeSmallLabel = UILabel()
    private let registSizeSmallStackView = UIStackView()
    private let registSizeSmallButton = RegistrationSelectButton(title: nil)
    private let registSizeMediumIcon = UIImageView()
    private let registSizeMediumLabel = UILabel()
    private let registSizeMediumStackView = UIStackView()
    private let registSizeMediumButton = RegistrationSelectButton(title: nil)
    private let registSizeLargeIcon = UIImageView()
    private let registSizeLargeLabel = UILabel()
    private let registSizeLargeStackView = UIStackView()
    private let registSizeLargeButton = RegistrationSelectButton(title: nil)
    private let registSizeStackButtonView = UIStackView()
    private let registAgeLabel = UILabel()
    private let registAgeButton = registBirthdayButton(title: "YYYY-MM-DD (n세)")
    private let registedAgeLabel = UILabel()
    private let registGenderLabel = UILabel()
    private let registGenderStackView = UIStackView()
    private let registGenderFemale = RegistrationSelectButton(title: "여아")
    private let registGenderMale = RegistrationSelectButton(title: "남아")
    private let registNeuteredLabel = UILabel()
    private let registNeuteredStackView = UIStackView()
    private let registNeuteredTrue = RegistrationSelectButton(title: "중성화 했어요")
    private let registNeuteredFalse = RegistrationSelectButton(title: "중성화 안 했어요")
    private let registIntroduceLabel = UILabel()
    private let registIntroduce = RegistrationTextField(text: "성격을 입력하세요")
    private let registIntroduceCountLabel = UILabel()
    private let registCompletButton = ButtonFactory.makeButton(type: .main, title: "다음")
    private let loadingIndicator = CustomLoadingIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAroundRx(disposeBag: disposeBag)
        
        setupUI()
        configureUI()
        
        updateButtonStates()
        bind()
    }
    
    /// Configures the view for the specified mode. If mode is .edit, sets up the viewModel with the profile.
    func configure(for mode: Mode) {
        self.mode = mode

        if case .edit(let profile) = mode {
            viewModel.setEditMode(with: profile)
        }

        DispatchQueue.main.async { [weak self] in
            if self?.isViewLoaded == true {
                self?.updateButtonStates()
            }
        }
    }
    
    private func updateButtonStates() {
        guard viewModel.isEditMode() else { return }
        
        // 크기 버튼 상태
        let selectedSize = viewModel.input.selectedSize.value
        registSizeSmallButton.isSelected = (selectedSize == "small")
        registSizeMediumButton.isSelected = (selectedSize == "medium")
        registSizeLargeButton.isSelected = (selectedSize == "large")
        
        // 성별 버튼 상태
        let selectedGender = viewModel.input.selectedGender.value
        registGenderFemale.isSelected = (selectedGender == "female")
        registGenderMale.isSelected = (selectedGender == "male")
        
        // 중성화 버튼 상태
        if let isNeutered = viewModel.input.isNeutered.value {
            registNeuteredTrue.isSelected = isNeutered
            registNeuteredFalse.isSelected = !isNeutered
        }
        
        // 이름 텍스트필드
        registName.text = viewModel.input.name.value
        registName.sendActions(for: .editingChanged)
        registNameCountLabel.text = "\(viewModel.input.name.value.count) / 10 자"
        
        // 성격 및 특성 텍스트필드
        registIntroduce.text = viewModel.input.introduce.value
        registIntroduce.sendActions(for: .editingChanged)
        registIntroduceCountLabel.text = "\(viewModel.input.introduce.value.count) / 18 자"
        
        // 프로필 이미지 로드
        loadProfileImage()
    }
    
    private func loadProfileImage() {
        guard case .edit(let profile) = viewModel.currentMode else { return }
        
        FirebaseImageManager.shared.getPetImageURL(
            petId: profile.petProfileId,
            userId: profile.userId
        ) { [weak self] url in
            guard let self else { return }
            
            let processor = DownsamplingImageProcessor(size: self.registedProfileImage.bounds.size) // 크기 지정 다운 샘플링
            
            self.registedProfileImage.kf.indicatorType = .activity
            KF.url(url)
                .placeholder(UIImage.petAvatar)
                .setProcessor(processor)
                .cacheOriginalImage()
                .fade(duration: 0.25)
                .onFailureImage(UIImage.petAvatar)
                .onSuccess { result in
                    self.selectedImage = result.image
                    self.cameraViewModel.output.capturedImage.accept(result.image)
                }
                .onFailure { error in }
                .set(to: self.registedProfileImage)
        }
    }
    
    func updateSizeSelectionButtons(selected: String) {
        // 아이콘 이미지 교체
        registSizeSmallIcon.image = selected == "small" ?
            UIImage(named: "smallDogActive") :
            UIImage(named: "smallDogInactive")
        registSizeSmallLabel.textColor = selected == "small" ?
            .textPrimary : .textTertiary

        registSizeMediumIcon.image = selected == "medium" ?
            UIImage(named: "mediumDogActive") :
            UIImage(named: "mediumDogInactive")
        registSizeMediumLabel.textColor = selected == "medium" ?
            .textPrimary : .textTertiary

        registSizeLargeIcon.image = selected == "large" ?
            UIImage(named: "largeDogActive") :
            UIImage(named: "largeDogInactive")
        registSizeLargeLabel.textColor = selected == "large" ?
            .textPrimary : .textTertiary
    }
    
    func bind() {
        Observable.combineLatest(
            self.cameraViewModel.output.capturedImage,
            self.viewModel.input.name,
            self.viewModel.input.breed,
            self.viewModel.input.selectedSize,
            self.viewModel.input.selectedGender,
            self.viewModel.input.isNeutered,
            self.viewModel.input.introduce,
            self.viewModel.input.selectedAge
        )
        .subscribe(onNext: { [weak self] image, name, breed, size, gender, isNeutered, introduce, age in
            if image != nil,
               name.count > 0,
               breed.count > 0,
               size.count > 0,
               gender.count > 0,
               isNeutered != nil,
               introduce.count > 0,
               age != nil {
                self?.registCompletButton.isEnabled = true
            } else {
                self?.registCompletButton.isEnabled = false
            }
        })
        .disposed(by: disposeBag)
        
        viewModel.output.isLoading
            .subscribe(onNext: { [weak self] isLoading in
                self?.registCompletButton.isEnabled = !isLoading
                self?.loadingIndicator.isHidden = !isLoading
            })
            .disposed(by: disposeBag)
        
        viewModel.titleText
            .bind(to: registrationLabel.rx.text)
            .disposed(by: disposeBag)
        
        self.registrationButton.rx.tap
            .subscribe(onNext: { [weak self]  _ in
                let alert = CustomAlertViewController(
                    message: "작성을 종료하시겠습니까?",
                    subMessage: "작성한 정보는 저장되지 않습니다.",
                    buttons: [
                        CustomAlertViewController.AlertButton(title: "취소", action: nil),
                        CustomAlertViewController.AlertButton(title: "확인", action: { [weak self] in
                            self?.dismiss(animated: true)
                        })
                    ]
                )
                
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
        
        cameraViewModel.output.capturedImage
            .subscribe(onNext: { [weak self] image in
                guard let self, let image else { return }
                
                self.selectedImage = image
                self.registedProfileImage.image = image
            })
            .disposed(by: disposeBag)
        
        self.registImage.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                let pictureViewModel = PictureUploadRequestViewModel()
                pictureViewModel.input.accept(.sender(.pictureRequestForPet))
                let requestView = UINavigationController(rootViewController: PictureUploadRequestViewController(viewModel: pictureViewModel, cameraViewModel: cameraViewModel))
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
        
        self.registName.rx.text
            .subscribe(onNext: { [weak self]  _ in
                guard let self,
                      let text = self.registName.text else { return }
                
                // 글자 공백 용납하지 않기
                let containsWhitespace = text.rangeOfCharacter(from: .whitespaces) != nil
                self.registNameAlertStackView.isHidden = !containsWhitespace
                
                self.registNameCountLabel.text = "\(text.count) / 10 자"
                
                if text.count > 10 {
                    let overText = text.count - 10
                    self.registName.text?.removeLast(overText)
                    self.registNameCountLabel.text = "10 / 10 자"
                }
            })
            .disposed(by: disposeBag)
        
        registName.rx.text.orEmpty
            .bind(to: viewModel.input.name)
            .disposed(by: disposeBag)
        
        self.registBreed.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let breedSearchVC = BreedSearchViewController()
                breedSearchVC.selectedBreed
                    .subscribe(onNext: { [weak owner] breed in
                        owner?.viewModel.input.breed.accept(breed)
                    })
                    .disposed(by: breedSearchVC.disposeBag)
                
                if let sheet = breedSearchVC.sheetPresentationController {
                    sheet.detents = [.large()]
                    sheet.selectedDetentIdentifier = .large
                    sheet.prefersGrabberVisible = true
                    sheet.preferredCornerRadius = 20
                    self.present(breedSearchVC, animated: true)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.input.breed
            .bind(to: registBreed.breedText)
            .disposed(by: disposeBag)
        
        // 크기 선택 바인딩
        Observable.merge(
            registSizeSmallButton.rx.tap.map { "small" },
            registSizeMediumButton.rx.tap.map { "medium" },
            registSizeLargeButton.rx.tap.map { "large" }
        )
        .bind(to: viewModel.input.selectedSize)
        .disposed(by: disposeBag)
        
        self.registSizeSmallButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registSizeSmallButton.isSelected = true
                self?.registSizeMediumButton.isSelected = false
                self?.registSizeLargeButton.isSelected = false
                self?.updateSizeSelectionButtons(selected: "small")
                self?.viewModel.input.selectedSize.accept("small")
            })
            .disposed(by: disposeBag)
        
        self.registSizeMediumButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registSizeSmallButton.isSelected = false
                self?.registSizeMediumButton.isSelected = true
                self?.registSizeLargeButton.isSelected = false
                self?.updateSizeSelectionButtons(selected: "medium")
                self?.viewModel.input.selectedSize.accept("medium")
            })
            .disposed(by: disposeBag)
        
        self.registSizeLargeButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registSizeSmallButton.isSelected = false
                self?.registSizeMediumButton.isSelected = false
                self?.registSizeLargeButton.isSelected = true
                self?.updateSizeSelectionButtons(selected: "large")
                self?.viewModel.input.selectedSize.accept("large")
            })
            .disposed(by: disposeBag)
        
        self.registAgeButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let birthSelectVC = BirthSelectViewController()
                birthSelectVC.selectedDate
                    .subscribe(onNext: { [weak owner] date in
                        owner?.viewModel.input.selectedAge.accept(date)
                    })
                    .disposed(by: birthSelectVC.disposeBag)
                
                if let sheet = birthSelectVC.sheetPresentationController {
                    if UIScreen.isIPhoneSE {
                        sheet.detents = [.medium()]
                        sheet.selectedDetentIdentifier = .medium
                    } else {
                        let customDetent = UISheetPresentationController.Detent.custom { _ in 360 }
                        sheet.detents = [customDetent, .medium()]
                        // 첫 번째 detent가 자동으로 선택됨
                    }
                    
                    sheet.prefersGrabberVisible = true
                    sheet.preferredCornerRadius = 20
                }
                owner.present(birthSelectVC, animated: true)
                
            })
            .disposed(by: disposeBag)
        
        viewModel.input.selectedAge
            .map { dateOpt in
                guard let date = dateOpt else { return "YYYY-MM-DD (n세)" }
                let age = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
                return "\(DateFormatter.yyyyMMdd.string(from: date)) (\(age)세)"
            }
            .bind(to: registAgeButton.dateText)
            .disposed(by: disposeBag)
        
        // 성별 선택 바인딩
        Observable.merge(
            registGenderFemale.rx.tap.map { "female" },
            registGenderMale.rx.tap.map { "male" }
        )
        .bind(to: viewModel.input.selectedGender)
        .disposed(by: disposeBag)
        
        self.registGenderFemale.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registGenderFemale.isSelected = true
                self?.registGenderMale.isSelected = false
            })
            .disposed(by: disposeBag)
        
        self.registGenderMale.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registGenderMale.isSelected = true
                self?.registGenderFemale.isSelected = false
            })
            .disposed(by: disposeBag)
        
        // 중성화 여부 바인딩
        Observable.merge(
            registNeuteredTrue.rx.tap.map { true },
            registNeuteredFalse.rx.tap.map { false }
        )
        .bind(to: viewModel.input.isNeutered)
        .disposed(by: disposeBag)
        
        self.registNeuteredTrue.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registNeuteredTrue.isSelected = true
                self?.registNeuteredFalse.isSelected = false
            })
            .disposed(by: disposeBag)
        
        self.registNeuteredFalse.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.registNeuteredFalse.isSelected = true
                self?.registNeuteredTrue.isSelected = false
            })
            .disposed(by: disposeBag)
        
        self.registIntroduce.rx.text
            .subscribe(onNext: { [weak self]  _ in
                guard let self,
                      let text = self.registIntroduce.text else { return }
                
                self.registIntroduceCountLabel.text = "\(text.count) / 18 자"
                
                if text.count > 18 {
                    let overText = text.count - 18
                    self.registIntroduce.text?.removeLast(overText)
                    self.registIntroduceCountLabel.text = "18 / 18 자"
                }
            })
            .disposed(by: disposeBag)
        
        registIntroduce.rx.text.orEmpty
            .bind(to: viewModel.input.introduce)
            .disposed(by: disposeBag)
        
        self.registCompletButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self,
                      let selectedImage = self.selectedImage else { return }
                
                if self.viewModel.isEditMode() {
                    // 편집 모드: 기존 프로필 업데이트
                    if case .edit(let originalProfile) = self.viewModel.currentMode {
                        self.viewModel.updateProfileWithImage(image: selectedImage, originalProfile: originalProfile)
                    }
                } else {
                    // 생성 모드: 새 프로필 생성
                    self.viewModel.uploadImageAndSaveProfile(image: selectedImage)
                }
                
                self.viewModel.output.saveResult
                    .take(1)
                    .observe(on: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success:
                            if self.viewModel.isEditMode() {
                                // 편집 완료 알림
                                if case .edit(let profile) = self.viewModel.currentMode {
                                    self.profileUpdateSubject.onNext(profile)
                                }
                            } else {
                                // 생성 완료
                                let petProfileID = self.viewModel.imageDocumentId
                                self.onProfileAdded?(petProfileID)
                            }
                            self.dismiss(animated: true)
                        case .failure(let error):
                            print("저장 실패: \(error)")
                        }
                    })
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
        
        viewModel.buttonTitle
            .bind(to: registCompletButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
    }
    
    // MARK: - Present Edit View for Profile
    /// Presents the edit view for a given pet profile ID.
    private func presentEditView(for profileId: String) {
        FirestoreManager.shared.fetchDocument(
            collection: "PetProfile",
            documentId: profileId,
            type: PetProfile.self
        )
        .subscribe(onSuccess: { [weak self] profile in
            guard let self = self else { return }

            let registrationVC = RegistrationViewController()
            registrationVC.configure(for: .edit(profile))

            registrationVC.profileUpdateSubject
                .take(1)
                .subscribe(onNext: { [weak self] _ in
                    self?.viewModel.profileDidUpdate.onNext(())
                })
                .disposed(by: registrationVC.disposeBag)

            // NOTE: Present or push registrationVC from the calling context as needed
        }, onFailure: { error in
            print("❌ Firestore에서 프로필 로딩 실패: \(error.localizedDescription)")
        })
        .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        [
            registrationLabel,
            registrationButton
        ].forEach { registrationStackView.addArrangedSubview($0) }
        
        [
            registNameAlertImage,
            registNameAlertLabel
        ].forEach { registNameAlertStackView.addArrangedSubview($0) }
        
        [
            registSizeSmallIcon,
            registSizeSmallLabel
        ].forEach { registSizeSmallStackView.addArrangedSubview($0) }
        
        [
            registSizeMediumIcon,
            registSizeMediumLabel
        ].forEach { registSizeMediumStackView.addArrangedSubview($0) }
        
        [
            registSizeLargeIcon,
            registSizeLargeLabel
        ].forEach { registSizeLargeStackView.addArrangedSubview($0) }
        
        registSizeSmallButton.addSubview(registSizeSmallStackView)
        
        registSizeMediumButton.addSubview(registSizeMediumStackView)
        
        registSizeLargeButton.addSubview(registSizeLargeStackView)
        
        [
            registSizeSmallButton,
            registSizeMediumButton,
            registSizeLargeButton
        ].forEach { registSizeStackButtonView.addArrangedSubview($0) }
        
        [
            registGenderFemale,
            registGenderMale,
        ].forEach { registGenderStackView.addArrangedSubview($0) }
        
        [
            registNeuteredTrue,
            registNeuteredFalse,
        ].forEach { registNeuteredStackView.addArrangedSubview($0) }
        
        registImage.addSubviews([registImageStamp, registedProfileImage])
        
        contentView.addSubviews([
            registImageShadow,
            registImage,
            registNameLabel,
            registName,
            registNameCountLabel,
            registNameAlertStackView,
            registBreedLabel,
            registBreed,
            underLine,
            registSizeLabel,
            registSizeStackButtonView,
            registAgeLabel,
            registAgeButton,
            registGenderLabel,
            registGenderStackView,
            registNeuteredLabel,
            registNeuteredStackView,
            registIntroduceLabel,
            registIntroduceCountLabel,
            registIntroduce,
        ])
        
        scrollView.addSubview(contentView)
        
        view.addSubviews([
            registrationStackView,
            topUnderLine,
            scrollView,
            registCompletButton,
            loadingIndicator
        ])
        
        //MARK: 배경 --
        view.backgroundColor = .keycolorBackground
        
        registrationLabel.text = "멍탐정 프로필 입력하기"
        registrationLabel.textColor = .textPrimary
        registrationLabel.font = .highlight3
        
        registrationButton.setTitle("닫기", for: .normal)
        registrationButton.titleLabel?.font = .title3
        registrationButton.setTitleColor(.keycolorPrimary2, for: .normal)
        
        topUnderLine.backgroundColor = .gray200
        
        //        scrollView.isScrollEnabled = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        
        sheetPresentationController?.prefersScrollingExpandsWhenScrolledToEdge = false
        
        //MARK: 사진 --
        registImageShadow.image = UIImage(named: "petProfileImageShadow")
        
        registImage.setImage(UIImage(named: "smallPolaroid"), for: .normal)
        
        let transToFigma = CGFloat.pi / 180
        registImageStamp.contentMode = .scaleAspectFit
        registImageStamp.image = .stamp
        registImageStamp.transform = CGAffineTransform(rotationAngle: transToFigma * -8.01)
        
        registedProfileImage.contentMode = .scaleAspectFill
        registedProfileImage.layer.cornerRadius = 4
        registedProfileImage.clipsToBounds = true
        registedProfileImage.transform = CGAffineTransform(rotationAngle: transToFigma * -8.01)
                
        //MARK: 이름 --
        registNameLabel.text = "이름"
        registNameLabel.textColor = .textPrimary
        registNameLabel.font = .body1
        
        registNameCountLabel.text = "0 / 10 자"
        registNameCountLabel.textColor = .gray400
        registNameCountLabel.font = .alert2
        
        registNameAlertStackView.axis = .horizontal
        registNameAlertStackView.spacing = 4
        registNameAlertStackView.alignment = .leading
        
        registNameAlertImage.image = UIImage(named: "alertMark")
        registNameAlertImage.contentMode = .scaleAspectFit
        
        registNameAlertLabel.text = "공백 없이 입력해 주세요"
        registNameAlertLabel.textColor = .textAlert
        registNameAlertLabel.font = .alert2
        
        //MARK: 견종 --
        registBreedLabel.text = "견종"
        registBreedLabel.textColor = .textPrimary
        registBreedLabel.font = .body1
        
        underLine.backgroundColor = .gray200
        
        //MARK: 크기 --
        registSizeLabel.text = "크기"
        registSizeLabel.textColor = .textPrimary
        registSizeLabel.font = .body1
        
        registSizeSmallIcon.image = UIImage(named: "smallDogInactive")
        registSizeSmallIcon.isUserInteractionEnabled = false
        registSizeSmallLabel.text = "소형견"
        registSizeSmallLabel.textColor = .textTertiary
        registSizeSmallLabel.font = .title3
        registSizeSmallLabel.isUserInteractionEnabled = false
        
        registSizeSmallStackView.backgroundColor = .clear
        registSizeSmallStackView.axis = .horizontal
        registSizeSmallStackView.spacing = 8
        registSizeSmallStackView.alignment = .center
        registSizeSmallStackView.isUserInteractionEnabled = false
        
        registSizeMediumIcon.image = UIImage(named: "mediumDogInactive")
        registSizeMediumIcon.isUserInteractionEnabled = false
        registSizeMediumLabel.text = "중형견"
        registSizeMediumLabel.textColor = .textTertiary
        registSizeMediumLabel.font = .title3
        registSizeMediumLabel.isUserInteractionEnabled = false
        
        registSizeMediumStackView.backgroundColor = .clear
        registSizeMediumStackView.axis = .horizontal
        registSizeMediumStackView.spacing = 8
        registSizeMediumStackView.alignment = .center
        registSizeMediumStackView.isUserInteractionEnabled = false
        
        registSizeLargeIcon.image = UIImage(named: "largeDogInactive")
        registSizeLargeIcon.isUserInteractionEnabled = false
        registSizeLargeLabel.text = "대형견"
        registSizeLargeLabel.textColor = .textTertiary
        registSizeLargeLabel.font = .title3
        registSizeLargeLabel.isUserInteractionEnabled = false
        
        registSizeLargeStackView.backgroundColor = .clear
        registSizeLargeStackView.axis = .horizontal
        registSizeLargeStackView.spacing = 8
        registSizeLargeStackView.alignment = .center
        registSizeLargeStackView.isUserInteractionEnabled = false
        
        registSizeStackButtonView.axis = .horizontal
        registSizeStackButtonView.spacing = 12
        registSizeStackButtonView.distribution = .fillEqually
        
        //MARK: 나이 --
        registAgeLabel.text = "나이"
        registAgeLabel.textColor = .textPrimary
        registAgeLabel.font = .body1
        
        registedAgeLabel.textColor = .textPrimary
        registedAgeLabel.font = .body3
        
        //MARK: 성별 --
        registGenderLabel.text = "성별"
        registGenderLabel.textColor = .textPrimary
        registGenderLabel.font = .body1
        
        registGenderStackView.axis = .horizontal
        registGenderStackView.spacing = 12
        registGenderStackView.alignment = .fill
        registGenderStackView.distribution = .fillEqually
        
        //MARK: 중성화 --
        registNeuteredLabel.text = "중성화"
        registNeuteredLabel.textColor = .textPrimary
        registNeuteredLabel.font = .body1
        
        registNeuteredStackView.axis = .horizontal
        registNeuteredStackView.spacing = 12
        registNeuteredStackView.alignment = .fill
        registNeuteredStackView.distribution = .fillEqually
        
        //MARK: 성격 및 특성 --
        registIntroduceLabel.text = "성격 및 특성"
        registIntroduceLabel.textColor = .textPrimary
        registIntroduceLabel.font = .body1
        
        registIntroduceCountLabel.text = "0 / 18 자"
        registIntroduceCountLabel.textColor = .gray400
        registIntroduceCountLabel.font = .alert2
        
        // MARK: 다음 버튼 --
        registCompletButton.isEnabled = false
    }
    
    private func configureUI() {
        
        registrationLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview()
        }
        
        registrationButton.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.trailing.equalToSuperview()
        }
        
        registrationStackView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(28)
        }
        
        topUnderLine.snp.makeConstraints {
            $0.top.equalTo(registrationLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
        }
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(topUnderLine.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(registCompletButton.snp.top).offset(-8)
        }
        
        contentView.snp.makeConstraints {
            $0.width.equalTo(scrollView.frameLayoutGuide)
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
        
        registImage.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalToSuperview()
            $0.height.equalTo(200)
            $0.width.equalTo(160)
        }
        
        registedProfileImage.snp.makeConstraints {
            $0.height.equalTo(112)
            $0.width.equalTo(104)
            $0.centerX.equalToSuperview().offset(1) // 이게
            $0.centerY.equalToSuperview().offset(2) // 최선입니다.
        }
        
        registImageShadow.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalToSuperview().offset(-16)
        }
        
        registImageStamp.snp.makeConstraints {
            $0.width.height.equalTo(48)
            $0.top.equalTo(registedProfileImage.snp.bottom).offset(-4)
            $0.trailing.equalTo(registedProfileImage.snp.leading).offset(24)
        }
        
        registNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(30)
            $0.leading.equalTo(registImage.snp.trailing)
            $0.height.equalTo(22)
        }
        
        registName.snp.makeConstraints {
            $0.top.equalTo(registNameLabel.snp.bottom).offset(8)
            $0.leading.equalTo(registImage.snp.trailing)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        registNameAlertImage.snp.makeConstraints {
            $0.height.equalTo(17)
        }
        
        registNameCountLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(30)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(24)
        }
        
        registNameAlertStackView.snp.makeConstraints {
            $0.top.equalTo(registName.snp.bottom).offset(4)
            $0.leading.equalTo(registImage.snp.trailing)
            $0.height.equalTo(24)
            $0.width.equalTo(132)
        }
        
        registBreedLabel.snp.makeConstraints {
            $0.top.equalTo(registName.snp.bottom).offset(32)
            $0.leading.equalTo(registImage.snp.trailing)
            $0.height.equalTo(22)
        }
        
        registBreed.snp.makeConstraints {
            $0.top.equalTo(registBreedLabel.snp.bottom).offset(8)
            $0.leading.equalTo(registImage.snp.trailing)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        underLine.snp.makeConstraints {
            $0.top.equalTo(registBreed.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(1)
        }
        
        registSizeLabel.snp.makeConstraints {
            $0.top.equalTo(underLine.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registSizeSmallIcon.snp.makeConstraints {
            $0.height.width.equalTo(20)
        }
        
        registSizeSmallStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        registSizeMediumIcon.snp.makeConstraints {
            $0.height.width.equalTo(20)
        }
        
        registSizeMediumStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        registSizeLargeIcon.snp.makeConstraints {
            $0.height.width.equalTo(20)
        }
        
        registSizeLargeStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        registSizeStackButtonView.snp.makeConstraints {
            $0.top.equalTo(registSizeLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        
        registAgeLabel.snp.makeConstraints {
            $0.top.equalTo(registSizeSmallButton.snp.bottom).offset(16)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registAgeButton.snp.makeConstraints {
            $0.top.equalTo(registAgeLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        registGenderLabel.snp.makeConstraints {
            $0.top.equalTo(registAgeButton.snp.bottom).offset(16)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registGenderStackView.snp.makeConstraints {
            $0.top.equalTo(registGenderLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
            
        }
        
        registNeuteredLabel.snp.makeConstraints {
            $0.top.equalTo(registGenderFemale.snp.bottom).offset(16)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registNeuteredStackView.snp.makeConstraints {
            $0.top.equalTo(registNeuteredLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        
        registIntroduceLabel.snp.makeConstraints {
            $0.top.equalTo(registNeuteredTrue.snp.bottom).offset(16)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }
        
        registIntroduceCountLabel.snp.makeConstraints {
            $0.top.equalTo(registNeuteredTrue.snp.bottom).offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(24)
        }
        
        registIntroduce.snp.makeConstraints {
            $0.top.equalTo(registIntroduceLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
        }
        
        registCompletButton.snp.remakeConstraints {  // 교차 제약 제거
            $0.height.equalTo(52)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        
        loadingIndicator.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
