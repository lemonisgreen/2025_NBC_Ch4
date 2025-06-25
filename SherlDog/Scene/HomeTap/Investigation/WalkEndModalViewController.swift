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
    private let disposeBag = DisposeBag()
    
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
    let walkShareButton = UIButton()
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
        
        self.DataTrackingVM.capturedImage
            .bind(to: self.mapImageView.rx.image)
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
        
        Observable
            .combineLatest(DataTrackingVM.startDate, DataTrackingVM.endDate)
            .compactMap { start, end -> String? in
                guard let start = start, let end = end else { return nil }
                let interval = Int(end.timeIntervalSince(start))
                let hours = interval / 3600
                let minutes = (interval % 3600) / 60
                let seconds = interval % 60
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            }
            .bind(to: timeContentLabel.rx.text)
            .disposed(by: disposeBag)
        
        closeButton.rx.tap
            .bind { [weak self] in
                self?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
        
        showProfileButton.rx.tap
            .bind { [weak self] in
                let requestViewModel = PictureUploadRequestViewModel()
                requestViewModel.input.accept(.sender(.sherlDogResult))
                let requestView = UINavigationController(rootViewController: PictureUploadRequestView(viewModel: requestViewModel))
                
                let dummyData = [0, 1, 2]
                if let sheet = requestView.sheetPresentationController {
                    sheet.selectedDetentIdentifier = .medium
                    sheet.prefersGrabberVisible = true
                    sheet.preferredCornerRadius = 20
                    
                    switch dummyData.count {
                    case 1: sheet.detents = [.custom { _ in 240 }]
                    case 2: sheet.detents = [.custom { _ in 320 }]
                    case 3: sheet.detents = [.custom { _ in 400 }]
                    default: return
                    }
                }
                
                self?.present(requestView, animated: true)
            }
            .disposed(by: disposeBag)
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
        
        for dogImage in dogImages {
            let imageView = UIImageView(image: dogImage)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.snp.makeConstraints {
                $0.width.height.equalTo(32)
            }
            dogImagesStack.addArrangedSubview(imageView)
        }
        
        dogImagesStack.axis = .horizontal
        dogImagesStack.spacing = -20
        dogImagesStack.alignment = .center
        dogImagesStack.backgroundColor = .clear
        
        mapImageView.image = UIImage(named: "mapPolaroid")
        mapImageView.contentMode = .scaleAspectFill
        mapImageView.clipsToBounds = true
        mapImageView.backgroundColor = .clear
        
        walkShareButton.setTitle("멍탐정과 남긴 단서", for: .normal)
        walkShareButton.titleLabel?.font = UIFont.highlight4
        walkShareButton.setTitleColor(UIColor(named: "textInverse"), for: .normal)
        walkShareButton.backgroundColor = UIColor(named: "keycolorPrimary3")
        walkShareButton.layer.cornerRadius = 6
        
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
