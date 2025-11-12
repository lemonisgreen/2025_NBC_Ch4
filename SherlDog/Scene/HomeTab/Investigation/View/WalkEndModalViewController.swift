//
//  WalkEndModalViewController.swift
//  SherlDog
//
//  Created by 전원식 on 6/9/25.
//

import UIKit
import RxSwift
import RxCocoa
import NMapsMap
import Kingfisher

class WalkEndModalViewController : UIViewController {
    
    private let dataTrackingViewModel: DataTrackingViewModel
    private let requestViewModel : PictureUploadRequestViewModel
    private let invLogListViewModel : InvLogListViewModel
    private let disposeBag = DisposeBag()
    private var selectedPetProfiles: [PetProfile] = []
    
    private let stepLabelWrapper = UIView()
    private let backgroundImageView = UIImageView()
    private let todayLabel = UILabel()
    private let distanceLabel = UILabel()
    private let timeLabel = UILabel()
    private let stepCountLabel = UILabel()
    private let distanceContentLabel = UILabel()
    private let timeContentLabel = UILabel()
    private let stepCountContentLabel = UILabel()
    private let dogImages: [UIImage] = [
        .sampleDog,
        .sampleDog,
        .sampleDog
    ]
    private let walkEndLabel = UILabel()
    private let showProfileButton = UIButton()
    private let walkShareButton = ButtonFactory.makeButton(type: .main, title: "수사 일지 공유하기")
    private let mapImageView = UIImageView()
    private let closeButton = UIButton()
    private let loadingIndicator = CustomLoadingIndicator()
    
    private let dogImagesStack = UIStackView()
    private let walkEndStack = UIStackView()
    private let infoStack = UIStackView()
    private let timeStack = UIStackView()
    private let distanceStack = UIStackView()
    private let stepCountStack = UIStackView()
    private let labelAndButtonStack = UIStackView()
    
    private let infoBox = UIView()
    private let walkEndBox = UIView()
    private let dividerLine = UIView()
    
    init(
        dataTrackingViewModel: DataTrackingViewModel,
        requestViewModel: PictureUploadRequestViewModel = PictureUploadRequestViewModel(),
        invLogListViewModel: InvLogListViewModel = InvLogListViewModel(),
        selectedProfiles: [PetProfile] = []
    ) {
        self.dataTrackingViewModel = dataTrackingViewModel
        self.requestViewModel = requestViewModel
        self.invLogListViewModel = invLogListViewModel
        self.selectedPetProfiles = selectedProfiles
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupUI()
        configureUI()
        bind()
    }
    
    private func bind() {
        
        self.dataTrackingViewModel.fullScreenImage
            .bind(onNext: { [weak self] image in
                guard let self = self,
                      self.dataTrackingViewModel.fetchResult.value == nil else { return }
                
                DispatchQueue.main.async {
                    self.mapImageView.image = image
                    self.isLoading(isLoading: true)
                    
                    self.dataTrackingViewModel.capturedImage.accept(self.mapImageView.viewCapture())
                }
            })
            .disposed(by: disposeBag)
        
        self.dataTrackingViewModel.capturedImage
            .bind(onNext: { [weak self] image in
                guard let self = self,
                      self.dataTrackingViewModel.fetchResult.value == nil else { return }
                
                self.dataTrackingViewModel.saveWalkResultCapturedImage(
                    image: image,
                    selectedProfiles: self.selectedPetProfiles
                )
            })
            .disposed(by: disposeBag)
        
        self.dataTrackingViewModel.saveResult
            .subscribe(onNext: { [weak self] result in
                guard let self = self,
                      self.dataTrackingViewModel.fetchResult.value == nil else { return }
                
                switch result {
                case .success():
                    self.isLoading(isLoading: false)
                    
                    let alert = CustomAlertViewController(
                        message: "산책이 기록되었습니다.",
                        subMessage: "마이페이지에서 확인하실 수 있습니다.",
                        buttons: [
                            CustomAlertViewController.AlertButton(
                                title: "닫기",
                                action: nil
                            )
                        ]
                    )
                    self.present(alert, animated: true)
                    
                case .failure(let error):
                    // TODO: 에러 처리
                    print(error.localizedDescription)
                    return
                }
            })
            .disposed(by: disposeBag)
        self.dataTrackingViewModel.fetchResult
            .bind(onNext: { [weak self] result in
                guard let self = self, let result = result else { return }
                
                self.fetchSelectedPetProfiles(petProfileIds: result.petProfileId)
            })
            .disposed(by: disposeBag)
        
        self.dataTrackingViewModel.walkingPathImageURL
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] urlString in
                guard let self,
                      let url = URL(string: urlString),
                      !urlString.isEmpty else { return }
                
                self.mapImageView.kf.setImage(
                    with: url,
                    placeholder: UIImage(named: "mapPolaroid"),
                    options: [.transition(.fade(0.25)),
                              .cacheOriginalImage]
                )
            })
            .disposed(by: disposeBag)
        
        
        self.walkShareButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self, let day = self.dataTrackingViewModel.endDate.value else { return }

                let clueViewModel = ClueDetailViewModel(day: day)
                
                Observable.combineLatest(
                    self.dataTrackingViewModel.numberOfSteps,
                    self.dataTrackingViewModel.distance,
                    self.dataTrackingViewModel.duration,
                    self.dataTrackingViewModel.endDate,
                    clueViewModel.clueCount
                )
                .take(1)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self, day] steps, distance, duration, endDate, clueCount in
                    guard let self else { return }
                    
                    let inv = InvData(
                        steps: steps,
                        distanceMeters: distance,
                        durationText: duration,
                        endDate: endDate,
                        clueCount: clueCount
                    )
                    
                    let requestViewModel = PictureUploadRequestViewModel()
                    requestViewModel.output.invData.accept(inv)
                    requestViewModel.input.accept(.sender(.pictureRequest))
                    
                    let requestView = UINavigationController(rootViewController: PictureUploadRequestViewController(viewModel: requestViewModel))
                    
                    if let sheet = requestView.sheetPresentationController {
                        sheet.setModalSize(type: .pictureWithoutAvatar, grabber: true)
                        sheet.preferredCornerRadius = 20
                    }
                    
                    self.present(requestView, animated: true)
                    
                    // 커뮤니티탭 개발 전, 이번 산책에서 남긴 단서 모아보기 기능
                    
                    //                let viewModel = ClueDetailViewModel(day: day)
                    //                let detailVC = ClueDetailViewController(viewModel: viewModel)
                    //                let nav = UINavigationController(rootViewController: detailVC)
                    //                nav.modalPresentationStyle = .pageSheet
                    //                nav.sheetPresentationController?.setModalSize(type: .clue, grabber: true)
                    //                self.present(nav, animated: true)
                })
                .disposed(by: self.disposeBag)
                
            })
            .disposed(by: disposeBag)
        
        dataTrackingViewModel.numberOfSteps
            .map { "\($0)"}
            .bind(to: stepCountContentLabel.rx.text)
            .disposed(by: disposeBag)
        
        dataTrackingViewModel.distance
            .map { String(format: "%.2f km", $0 / 1000.0) }
            .bind(to: distanceContentLabel.rx.text)
            .disposed(by: disposeBag)
        
        dataTrackingViewModel.endDate
            .map {
                guard let endDate = $0 else { return "date" }
                return DateFormatter.yyyyMMddSlash.string(from: endDate)
            }
            .bind(to: self.todayLabel.rx.text)
            .disposed(by: disposeBag)
        
        dataTrackingViewModel.duration
            .bind(to: self.timeContentLabel.rx.text)
            .disposed(by: disposeBag)
        
        closeButton.rx.tap
            .bind { [weak self] in
                self?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
        
        showProfileButton.rx.tap
            .bind { [weak self] in
                guard let self = self else { return }
                
                // 현재 모달에 전달된 선택된 강아지 사용
                let requestViewModel = PictureUploadRequestViewModel()
                
                // 선택된 강아지 데이터를 새 requestViewModel에 설정
                requestViewModel.output.selectedPetProfiles.accept(self.selectedPetProfiles)
                requestViewModel.fetchPetProfiles() // 전체 프로필도 로드
                
                requestViewModel.input.accept(.sender(.sherlDogResult))
                let requestView = UINavigationController(rootViewController: PictureUploadRequestViewController(viewModel: requestViewModel))
                
                switch self.selectedPetProfiles.count {
                case 1: requestView.sheetPresentationController?.setModalSize(type: .onePet, grabber: true)
                case 2: requestView.sheetPresentationController?.setModalSize(type: .twoPet, grabber: true)
                case 3: requestView.sheetPresentationController?.setModalSize(type: .thrPet, grabber: true)
                default: requestView.sheetPresentationController?.setModalSize(type: .thrPet, grabber: true)
                }
                
                self.present(requestView, animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func isLoading(isLoading: Bool) {
        self.walkShareButton.isEnabled = !isLoading
        self.closeButton.isEnabled = !isLoading
        self.showProfileButton.isEnabled = !isLoading
        self.loadingIndicator.isHidden = !isLoading
    }
    
    private func fetchSelectedPetProfiles(petProfileIds: [String]) {
        let profileObservables = petProfileIds.map { id in
            FirestoreManager.shared.fetchQuery(
                FirestoreQuery<PetProfile>(
                    collection: .petProfile,
                    type: .document(id: id)
                    
                )
            )
        }
        
        Single.zip(profileObservables)
            .subscribe(onSuccess: { [weak self] profilesArray in
                guard let self = self else { return }
                
                // 2차원 배열을 1차원 배열로 펼치기
                let flattenedProfiles = profilesArray.flatMap { $0 }
                
                self.selectedPetProfiles = flattenedProfiles
                self.setPetImages()
            }, onFailure: { error in
                print("펫프로필 조회 실패: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    func addVerticalSeparators() {
        infoBox.layoutIfNeeded()
        
        let totalWidth = infoBox.bounds.width
        let sectionCount = infoStack.arrangedSubviews.count
        let sectionWidth = totalWidth / CGFloat(sectionCount)
        
        for i in 1..<sectionCount {
            let xPos = sectionWidth * CGFloat(i)
            let line = CALayer()
            line.frame = CGRect(
                x: xPos,
                y: 0,
                width: 1 / UIScreen.main.scale,
                height: infoBox.bounds.height
            )
            line.backgroundColor = UIColor(named: "gray300")?.cgColor
            line.name = "vLine"
            infoBox.layer.addSublayer(line)
        }
    }
    
    private func setupUI() {
        [
            backgroundImageView,
            todayLabel,
            distanceLabel,
            timeLabel,
            stepCountLabel,
            distanceContentLabel,
            timeContentLabel,
            stepCountContentLabel,
            walkEndLabel,
            showProfileButton,
            walkShareButton,
            timeStack,
            distanceStack,
            stepCountStack,
            labelAndButtonStack,
            mapImageView,
            infoBox,
            walkEndBox,
            dividerLine,
            closeButton,
            loadingIndicator
        ].forEach {
            view.addSubview($0)
        }
        
        infoBox.addSubview(infoStack)
        walkEndBox.addSubview(walkEndStack)
        stepLabelWrapper.addSubview(stepCountLabel)
        
        infoBox.layer.borderWidth = 1
        infoBox.layer.borderColor = UIColor(named: "gray300")?.cgColor
        infoBox.layer.cornerRadius = 2
        infoBox.backgroundColor = .clear
        
        walkEndBox.layer.borderWidth = 1
        walkEndBox.layer.borderColor = UIColor(named: "gray300")?.cgColor
        walkEndBox.layer.cornerRadius = 2
        walkEndBox.backgroundColor = .clear
        
        dividerLine.backgroundColor = UIColor(named: "gray300")
        
        backgroundImageView.image = .endInvestigation
        backgroundImageView.contentMode = UIScreen.isIPhoneSE ? .scaleAspectFill : .scaleAspectFit
        view.insertSubview(backgroundImageView, at: 0)
        
        todayLabel.text = "2025/06/05"
        todayLabel.textColor = UIColor(named: "keycolorPrimary2")
        todayLabel.font = (UIScreen.isIPhoneSE || UIScreen.isIPhoneMini) ? .recordTitleIsSE : .recordTitle
        todayLabel.backgroundColor = .clear
        
        distanceLabel.text = "거리"
        distanceLabel.textColor = UIColor(named: "textTertiary")
        distanceLabel.textAlignment = .left
        distanceLabel.font = UIFont.body6
        distanceLabel.backgroundColor = .clear
        
        timeLabel.text = "시간"
        timeLabel.textColor = UIColor(named: "textTertiary")
        timeLabel.textAlignment = .left
        timeLabel.font = UIFont.body6
        timeLabel.backgroundColor = .clear
        
        stepCountLabel.text = "걸음 수"
        stepCountLabel.textColor = UIColor(named: "textTertiary")
        stepCountLabel.textAlignment = .right
        stepCountLabel.font = UIFont.body6
        stepCountLabel.backgroundColor = .clear
        
        distanceContentLabel.textColor = UIColor(named: "textSecondary")
        distanceContentLabel.font = UIFont.highlight3
        distanceContentLabel.backgroundColor = .clear
        
        timeContentLabel.textColor = UIColor(named: "textSecondary")
        timeContentLabel.font = UIFont.highlight3
        timeContentLabel.backgroundColor = .clear
        timeContentLabel.textAlignment = .left
        
        stepCountContentLabel.textColor = UIColor(named: "textSecondary")
        stepCountContentLabel.font = UIFont.highlight3
        stepCountContentLabel.backgroundColor = .clear
        stepCountContentLabel.textAlignment = .center
        stepCountContentLabel.lineBreakMode = .byClipping
        
        
        walkEndStack.arrangedSubviews.forEach {
            walkEndStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        walkEndLabel.textColor = UIColor(named: "textSecondary")
        walkEndLabel.font = UIFont.title1
        walkEndLabel.text = "멍탐정 수사 완료!"
        walkEndLabel.backgroundColor = .clear
        
        walkEndStack.axis = .horizontal
        walkEndStack.alignment = .center
        walkEndStack.backgroundColor = .clear
        walkEndStack.spacing = 12
        walkEndStack.addArrangedSubview(dogImagesStack)
        walkEndStack.addArrangedSubview(labelAndButtonStack)
        
        labelAndButtonStack.axis = .horizontal
        labelAndButtonStack.spacing = 8
        labelAndButtonStack.alignment = .center
        labelAndButtonStack.addArrangedSubview(walkEndLabel)
        labelAndButtonStack.addArrangedSubview(showProfileButton)
        
        showProfileButton.setImage(UIImage(named: "showProfile"), for: .normal)
        showProfileButton.contentMode = .scaleAspectFit
        showProfileButton.snp.makeConstraints { $0.size.equalTo(CGSize(width: 75, height: 28)) }
        
        dogImagesStack.axis = .horizontal
        dogImagesStack.spacing = -20
        dogImagesStack.alignment = .center
        dogImagesStack.backgroundColor = .clear
        // 선택된 강아지들의 실제 이미지 사용
        setPetImages()
        
        mapImageView.image = UIImage(named: "mapPolaroid")
        mapImageView.contentMode = .scaleAspectFill
        mapImageView.clipsToBounds = true
        mapImageView.backgroundColor = .clear
        
        distanceStack.axis = .vertical
        distanceStack.spacing = 4
        distanceStack.alignment = .leading
        distanceStack.addArrangedSubview(distanceLabel)
        distanceStack.addArrangedSubview(distanceContentLabel)
        distanceStack.backgroundColor = .clear
        
        timeStack.axis = .vertical
        timeStack.spacing = 4
        timeStack.alignment = .leading
        timeStack.addArrangedSubview(timeLabel)
        timeStack.addArrangedSubview(timeContentLabel)
        timeStack.backgroundColor = .clear
        
        stepCountStack.axis = .vertical
        stepCountStack.spacing = 4
        stepCountStack.alignment = .fill
        stepCountStack.addArrangedSubview(stepLabelWrapper)
        stepCountStack.addArrangedSubview(stepCountContentLabel)
        stepCountStack.backgroundColor = .clear
        
        infoStack.axis = .horizontal
        infoStack.distribution = .fillEqually
        infoStack.addArrangedSubview(distanceStack)
        infoStack.addArrangedSubview(timeStack)
        infoStack.addArrangedSubview(stepCountStack)
        infoStack.backgroundColor = .clear
        
        closeButton.setImage(UIImage(named: "modalExit"), for: .normal)
        closeButton.contentMode = .scaleAspectFit
    }
    
    private func setPetImages() {
        dogImagesStack.arrangedSubviews.forEach {
            dogImagesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        // 선택된 강아지들의 실제 이미지 사용
        if !selectedPetProfiles.isEmpty {
            for profile in selectedPetProfiles {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 16 // 32/2
                imageView.layer.borderColor = UIColor(named: "textInverse")?.cgColor
                imageView.layer.borderWidth = 1
                imageView.snp.makeConstraints {
                    $0.width.height.equalTo(32)
                }
                
                // URL에서 이미지 로드
                if let url = URL(string: profile.image) {
                    let processor = DownsamplingImageProcessor(size: CGSize(width: 100, height: 100)) // 크기 지정 다운 샘플링
                    
                    imageView.kf.indicatorType = .activity
                    KF.url(url)
                        .placeholder(UIImage.petAvatar)
                        .setProcessor(processor)
                        .cacheOriginalImage()
                        .fade(duration: 0.25)
                        .onFailureImage(UIImage.petAvatar)
                        .onSuccess { result in }
                        .onFailure { error in }
                        .set(to: imageView)
                }
                
                dogImagesStack.addArrangedSubview(imageView)
            }
        } else {
            // 기본 이미지 사용 (선택된 강아지가 없을 때)
            for dogImage in dogImages {
                let imageView = UIImageView(image: dogImage)
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 16
                imageView.snp.makeConstraints {
                    $0.width.height.equalTo(32)
                }
                dogImagesStack.addArrangedSubview(imageView)
            }
        }
    }
    
    private func configureUI() {
        if UIScreen.isIPhoneSE {
            backgroundImageView.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview()
                $0.top.bottom.equalToSuperview().offset(25)
            }
        } else {
            backgroundImageView.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview()
                $0.top.bottom.equalToSuperview().offset(40)
            }
        }
        
        todayLabel.snp.makeConstraints {
            $0.top.equalTo(backgroundImageView.snp.top).offset(UIScreen.isIPhoneSE ? 55 : 75)
            $0.leading.equalTo(backgroundImageView.snp.leading).inset(60) // 36
            $0.trailing.equalTo(backgroundImageView.snp.trailing).inset(199)
        }
        
        infoBox.snp.makeConstraints {
            $0.top.equalTo(todayLabel.snp.bottom).offset(60)
            $0.leading.trailing.equalToSuperview().inset(30)
        }
        
        if (UIScreen.isIPhoneSE || UIScreen.isIPhoneMini) {
            stepCountLabel.snp.makeConstraints {
                $0.trailing.equalToSuperview().inset(45)
            }
        } else {
            stepCountLabel.snp.makeConstraints {
                $0.trailing.equalToSuperview().inset(55)
            }
        }
        
        stepCountContentLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(45)
        }
        
        infoStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(20)
        }
        
        walkEndBox.snp.makeConstraints {
            $0.top.equalTo(infoBox.snp.bottom).offset(15)
            $0.leading.trailing.equalToSuperview().inset(30)
        }
        
        dividerLine.snp.makeConstraints {
            $0.top.equalTo(walkEndBox.snp.bottom).offset(15)
            $0.leading.trailing.equalToSuperview().inset(30)
            $0.height.equalTo(1 / UIScreen.main.scale)
        }
        
        walkEndStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(20)
        }
        
        if UIScreen.isIPhoneSE {
            mapImageView.snp.makeConstraints {
                $0.top.equalTo(walkEndStack.snp.bottom).offset(45)
                $0.bottom.equalTo(walkShareButton.snp.top).offset(-8)
                $0.leading.trailing.equalToSuperview().inset(33)
            }
        } else {
            mapImageView.snp.makeConstraints {
                $0.top.equalTo(walkEndStack.snp.bottom).offset(45)
                $0.bottom.equalTo(walkShareButton.snp.top).offset(-12)
                $0.leading.trailing.equalToSuperview().inset(33)
            }
        }
        
        if UIScreen.isIPhoneSE {
            walkShareButton.snp.makeConstraints {
                $0.top.equalTo(mapImageView.snp.bottom).offset(UIScreen.isIPhoneSE ? 20 : 20)
                $0.height.equalTo(52)
                $0.leading.equalTo(backgroundImageView.snp.leading).inset(30)
                $0.trailing.equalTo(backgroundImageView.snp.trailing).inset(30)
                $0.bottom.equalTo(backgroundImageView.snp.bottom).inset(95)
            }
        } else {
            walkShareButton.snp.makeConstraints {
                $0.top.equalTo(mapImageView.snp.bottom).offset(24)
                $0.height.equalTo(52)
                $0.leading.equalTo(backgroundImageView.snp.leading).inset(30)
                $0.trailing.equalTo(backgroundImageView.snp.trailing).inset(30)
                $0.bottom.equalTo(backgroundImageView.snp.bottom).inset(140) // 109
            }
        }
        
        closeButton.snp.makeConstraints {
            $0.top.equalTo(todayLabel.snp.bottom).offset(UIScreen.isIPhoneSE ? 20 : 30)
            $0.trailing.equalToSuperview().inset(30)
            $0.width.height.equalTo(24)
        }
        
        loadingIndicator.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        infoBox.layer.sublayers?.removeAll(where: { $0.name == "vLine" })
        addVerticalSeparators()
    }
}
