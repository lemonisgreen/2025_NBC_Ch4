//
//  WalkEndModalViewController.swift
//  SherlDog
//
//  Created by 전원식 on 6/9/25.
//

import UIKit
import RxSwift
import RxCocoa

class WalkEndModalViewController : UIViewController {
    
    private let DataTrackingVM: DataTrackingViewModel
    private let requestViewModel = PictureUploadRequestViewModel()
    private let disposeBag = DisposeBag()
    // 선택된 강아지 정보를 받을 프로퍼티
    var selectedPetProfiles: [PetProfile] = []
    
    let stepLabelWrapper = UIView()
    let backgroundImageView = UIImageView()
    let todayLabel = UILabel()
    let distanceLabel = UILabel()
    let timeLabel = UILabel()
    let stepCountLabel = UILabel()
    let distanceContentLabel = UILabel()
    let timeContentLabel = UILabel()
    let stepCountContentLabel = UILabel()
    let dogImages: [UIImage] = [
        .sampleDog,
        .sampleDog,
        .sampleDog
    ]
    let walkEndLabel = UILabel()
    let showProfileButton = UIButton()
    let walkShareButton = ButtonManager(title: "멍탐정과 남긴 단서")
    let mapImageView = UIImageView()
    let closeButton = UIButton()
    
    let dogImagesStack = UIStackView()
    let walkEndStack = UIStackView()
    let infoStack = UIStackView()
    let timeStack = UIStackView()
    let distanceStack = UIStackView()
    let stepCountStack = UIStackView()
    let labelAndButtonStack = UIStackView()
    
    let infoBox = UIView()
    let walkEndBox = UIView()
    let dividerLine = UIView()
    
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
    
    //함께 산책한 강아지 정보 받아오기용 init
    init(viewModel: DataTrackingViewModel, selectedProfiles: [PetProfile] = []) {
        self.DataTrackingVM = viewModel
        self.selectedPetProfiles = selectedProfiles
        super.init(nibName: nil, bundle: nil)
    }
    
    init(viewModel: DataTrackingViewModel) {
        self.DataTrackingVM = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupUI()
        configureUI()
        bind()
    }
    
    private func bind() {
        
        self.DataTrackingVM.fullScreenImage
            .bind(onNext: { [weak self] image in
                guard let self,
                      self.DataTrackingVM.fetchResult.value == nil else { return }
                
                DispatchQueue.main.async {
                    self.mapImageView.image = image
                    self.isLoading(isLoading: true)
                    
                    self.DataTrackingVM.capturedImage.accept(self.mapImageView.viewCapture())
                }
            })
            .disposed(by: disposeBag)
        
        self.DataTrackingVM.capturedImage
            .bind(onNext: { [weak self] image in
                guard let self,
                      self.DataTrackingVM.fetchResult.value == nil else { return }
                
                self.DataTrackingVM.saveWalkResultCapturedImage(
                    image: image,
                    selectedProfiles: self.selectedPetProfiles
                )
            })
            .disposed(by: disposeBag)
        
        self.DataTrackingVM.saveResult
            .subscribe(onNext: { [weak self] result in
                guard let self,
                      self.DataTrackingVM.fetchResult.value == nil else { return }
                
                switch result {
                case .success():
                    self.isLoading(isLoading: false)
                    
                    let alert = AlertManager(message: "산책이 기록되었습니다.",
                                             subMessage: "마이페이지에서 확인하실 수 있습니다.",
                                             buttonTitles: ["닫기"],
                                             buttonActions: [nil])
                    self.present(alert, animated: true)
                    
                case .failure(let error):
                    // todo: 에러 처리
                    print(error.localizedDescription)
                    return
                }
            })
            .disposed(by: disposeBag)
        
        self.DataTrackingVM.fetchResult
            .bind(onNext: { [weak self] result in
                guard let self, let result else { return }
                
                self.selectedPetProfiles = result.petProfileId
                self.setPetImages()
            })
            .disposed(by: disposeBag)
        
        self.DataTrackingVM.invLogListViewSendImage
            .bind(onNext: { [weak self] image in
                guard let self,
                      self.DataTrackingVM.fetchResult.value != nil else { return }
                
                self.mapImageView.image = image
            })
            .disposed(by: disposeBag)
        
        self.walkShareButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                let requestViewModel = PictureUploadRequestViewModel()
                requestViewModel.input.accept(.sender(.pictureRequest))
                let requestView = UINavigationController(rootViewController: PictureUploadRequestView(viewModel: requestViewModel))
                
                if let sheet = requestView.sheetPresentationController {
                    sheet.detents = [.custom { _ in 320 }]
                    sheet.selectedDetentIdentifier = .medium
                    sheet.prefersGrabberVisible = true
                    sheet.preferredCornerRadius = 20
                }
                
                self?.present(requestView, animated: true)
            })
            .disposed(by: disposeBag)
        
        DataTrackingVM.numberOfSteps
            .map { "\($0)"}
            .bind(to: stepCountContentLabel.rx.text)
            .disposed(by: disposeBag)
        
        DataTrackingVM.distance
            .map { String(format: "%.2f km", $0 / 1000.0) }
            .bind(to: distanceContentLabel.rx.text)
            .disposed(by: disposeBag)
        
        DataTrackingVM.endDate
            .map {
                guard let endDate = $0 else { return "date" }
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy/MM/dd"
                return dateFormatter.string(from: endDate)
            }
            .bind(to: self.todayLabel.rx.text)
            .disposed(by: disposeBag)
        
        DataTrackingVM.duration
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
                let requestView = UINavigationController(rootViewController: PictureUploadRequestView(viewModel: requestViewModel))
                
                if let sheet = requestView.sheetPresentationController {
                    sheet.selectedDetentIdentifier = .medium
                    sheet.prefersGrabberVisible = true
                    sheet.preferredCornerRadius = 20
                    
                    switch self.selectedPetProfiles.count {
                    case 1: sheet.detents = [.custom { _ in 240 }]
                    case 2: sheet.detents = [.custom { _ in 320 }]
                    case 3: sheet.detents = [.custom { _ in 400 }]
                    default: sheet.detents = [.custom { _ in 400 }]
                    }
                }
                
                self.present(requestView, animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func isLoading(isLoading: Bool) {
            self.walkShareButton.isEnabled = !isLoading
            self.closeButton.isEnabled = !isLoading
            self.showProfileButton.isEnabled = !isLoading
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
            closeButton
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
        backgroundImageView.contentMode = .scaleAspectFit
        view.insertSubview(backgroundImageView, at: 0)
        
        todayLabel.text = "2025/06/05"
        todayLabel.textColor = UIColor(named: "keycolorPrimary2")
        todayLabel.font = UIFont.title3
        todayLabel.textAlignment = .left
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
        
        stepCountLabel.text = "걸음수"
        stepCountLabel.textColor = UIColor(named: "textTertiary")
        stepCountLabel.textAlignment = .right
        stepCountLabel.font = UIFont.body6
        stepCountLabel.backgroundColor = .clear
        
        //        distanceContentLabel.text = "11.23km"
        distanceContentLabel.textColor = UIColor(named: "textSecondary")
        distanceContentLabel.font = UIFont.highlight3
        distanceContentLabel.backgroundColor = .clear
        
        //        timeContentLabel.text = "10:11:12"
        timeContentLabel.textColor = UIColor(named: "textSecondary")
        timeContentLabel.font = UIFont.highlight3
        timeContentLabel.backgroundColor = .clear
        timeContentLabel.textAlignment = .left
        
        //        stepCountContentLabel.text = "12345"
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
        
//        for dogImage in dogImages {
//            let imageView = UIImageView(image: dogImage)
//            imageView.contentMode = .scaleAspectFill
//            imageView.clipsToBounds = true
//            imageView.snp.makeConstraints {
//                $0.width.height.equalTo(32)
//            }
//            dogImagesStack.addArrangedSubview(imageView)
//        }
//        
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
        
//        walkShareButton.setTitle("멍탐정과 남긴 단서", for: .normal)
//        walkShareButton.titleLabel?.font = UIFont.highlight4
//        walkShareButton.setTitleColor(UIColor(named: "textInverse"), for: .normal)
//        walkShareButton.backgroundColor = UIColor(named: "keycolorPrimary3")
//        walkShareButton.layer.cornerRadius = 6
        
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
                    DispatchQueue.global().async {
                        if let data = try? Data(contentsOf: url),
                           let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                imageView.image = image
                            }
                        }
                    }
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
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        todayLabel.snp.makeConstraints {
            $0.top.equalTo(backgroundImageView.snp.top).offset(75)
            $0.leading.equalTo(backgroundImageView.snp.leading).inset(60) // 36
            $0.trailing.equalTo(backgroundImageView.snp.trailing).inset(199)
        }
        
        infoBox.snp.makeConstraints {
            $0.top.equalTo(todayLabel.snp.bottom).offset(60)
            $0.leading.trailing.equalToSuperview().inset(30)
        }
        
        stepCountLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(55)
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
        
        mapImageView.snp.makeConstraints {
            $0.top.equalTo(walkEndStack.snp.bottom).offset(45) // 45
            $0.bottom.equalTo(walkShareButton.snp.top).offset(-12) // 32
            $0.leading.trailing.equalToSuperview().inset(33)
        }
        
        walkShareButton.snp.makeConstraints {
            $0.top.equalTo(mapImageView.snp.bottom).offset(24)
            $0.height.equalTo(52)
            $0.leading.equalTo(backgroundImageView.snp.leading).inset(30)
            $0.trailing.equalTo(backgroundImageView.snp.trailing).inset(30)
            $0.bottom.equalTo(backgroundImageView.snp.bottom).inset(140) // 109
        }
        
        closeButton.snp.makeConstraints {
            $0.top.equalTo(todayLabel.snp.bottom).offset(30)
            $0.trailing.equalToSuperview().inset(30)
            $0.width.height.equalTo(24)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        infoBox.layer.sublayers?.removeAll(where: { $0.name == "vLine" })
        addVerticalSeparators()
    }
}
