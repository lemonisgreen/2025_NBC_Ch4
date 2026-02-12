//
//  WalkEndModalViewController.swift
//  SherlDog
//
//  Created by 전원식 on 6/9/25.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher
import SnapKit
import FirebaseFirestore

final class WalkEndModalViewController: UIViewController {
    
    // MARK: - Mode
    enum Mode {
        case live(
            screenshot: UIImage,
            session: WalkSession.State,
            selectedProfiles: [PetProfile]
        )
        case history(
            result: WalkResult,
            selectedProfiles: [PetProfile]?
        )
    }
    
    // MARK: - Dependencies
    private let viewModel: WalkResultViewModel
    private let mode: Mode
    private let disposeBag = DisposeBag()
    
    // MARK: - State
    private var selectedPetProfiles: [PetProfile] = []
    
    // MARK: - UI
    private let backgroundImageView = UIImageView()
    private let todayLabel = UILabel()
    
    private let mapImageView = UIImageView()
    private let closeButton = UIButton()
    private let loadingIndicator = CustomLoadingIndicator()
    
    private let infoBox = UIView()
    private let infoBoxLine = UIView()
    private let walkEndBox = UIView()
    private let dividerLine = UIView()
    
    private let distanceLabel = UILabel()
    private let timeLabel = UILabel()
    private let stepCountLabel = UILabel()
    
    private let distanceContentLabel = UILabel()
    private let timeContentLabel = UILabel()
    private let stepCountContentLabel = UILabel()
    
    private let walkEndLabel = UILabel()
    private let showProfileButton = UIButton()
    
    // 수사일지 공유
    // private let walkShareButton = ButtonFactory.makeButton(type: .main, title: "수사 일지 공유하기")
    
    // 단서 보기
    private let walkShareButton = ButtonFactory.makeButton(type: .main, title: "단서 확인하기")
    
    private let infoStack = UIStackView()
    private let distanceStack = UIStackView()
    private let timeStack = UIStackView()
    private let stepCountStack = UIStackView()
    private let stepLabelWrapper = UIView()
    
    private let walkEndStack = UIStackView()
    private let dogImagesStack = UIStackView()
    private let labelAndButtonStack = UIStackView()
    private let todayInvPathLabel = UIImageView()
    private let mapBackgroundImageView = UIImageView()
    
    // MARK: - Init
    init(
        mode: Mode,
        viewModel: WalkResultViewModel = WalkResultViewModel()
    ) {
        self.mode = mode
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    
    convenience init(
        screenshot: UIImage,
        session: WalkSession.State,
        selectedProfiles: [PetProfile],
        viewModel: WalkResultViewModel = WalkResultViewModel()
    ) {
        self.init(
            mode: .live(screenshot: screenshot, session: session, selectedProfiles: selectedProfiles),
            viewModel: viewModel
        )
    }
    
    convenience init(
        result: WalkResult,
        selectedProfiles: [PetProfile]? = nil,
        viewModel: WalkResultViewModel = WalkResultViewModel()
    ) {
        self.init(
            mode: .history(result: result, selectedProfiles: selectedProfiles),
            viewModel: viewModel
        )
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        setupUI()
        setupConstraints()
        bind()
        renderByMode()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        infoBox.layer.sublayers?.removeAll(where: { $0.name == "vLine" })
        addVerticalSeparators()
    }
}

// MARK: - Bindings
private extension WalkEndModalViewController {
    
    func bind() {
        closeButton.rx.tap
            .bind { [weak self] in self?.dismiss(animated: true) }
            .disposed(by: disposeBag)
        
        showProfileButton.rx.tap
            .bind { [weak self] in self?.presentSelectedProfilesSheet() }
            .disposed(by: disposeBag)
        
        // 남긴 단서 보기
        walkShareButton.rx.tap
            .bind { [weak self] in self?.presentCluesFlow() }
            .disposed(by: disposeBag)
        
        // 수사일지 공유 flow
        //        walkShareButton.rx.tap
        //            .bind { [weak self] in self?.presentShareFlow() }
        //            .disposed(by: disposeBag)
        
        viewModel.saveResult
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                guard let self else { return }
                self.setLoading(false)
                
                switch result {
                case .success:
                    self.presentSavedAlert()
                case .failure(let error):
                    self.presentSaveFailAlert(message: error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Render (Mode)
private extension WalkEndModalViewController {
    
    func renderByMode() {
        switch mode {
        case let .live(screenshot, session, profiles):
            selectedPetProfiles = profiles
            renderLive(screenshot: screenshot, session: session)
            
        case let .history(result, injectedProfiles):
            if let injectedProfiles {
                selectedPetProfiles = injectedProfiles
                renderHistory(result: result)
            } else {
                fetchSelectedPetProfiles(petProfileIds: result.petProfileId) { [weak self] profiles in
                    guard let self else { return }
                    self.selectedPetProfiles = profiles
                    self.renderHistory(result: result)
                }
            }
        }
    }
    
    func renderLive(screenshot: UIImage, session: WalkSession.State) {
        mapImageView.image = screenshot
        
        let endDate = session.endDate ?? Date()
        todayLabel.text = DateFormatter.yyyyMMddSlash.string(from: endDate)
        
        stepCountContentLabel.text = "\(session.steps)"
        distanceContentLabel.text = String(format: "%.2f km", session.distanceMeters / 1000.0)
        timeContentLabel.text = formatDuration(seconds: session.elapsedSeconds)
        
        setPetImages()
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.setLoading(true)
            self.viewModel.uploadWalkingPathImageAndSaveResult(
                image: screenshot,
                session: session,
                selectedProfiles: self.selectedPetProfiles
            )
        }
    }
    
    func renderHistory(result: WalkResult) {
        todayLabel.text = formattedDateText(from: result.date)
        
        stepCountContentLabel.text = "\(result.steps)"
        distanceContentLabel.text = String(format: "%.2f km", result.distance / 1000.0)
        timeContentLabel.text = result.duration
        
        setPetImages()
        
        if let url = URL(string: result.walkingPathImage), !result.walkingPathImage.isEmpty {
            mapImageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "mapPolaroid"),
                options: [.transition(.fade(0.25)), .cacheOriginalImage]
            )
        } else {
            mapImageView.image = UIImage(named: "mapPolaroid")
        }
        
        setLoading(false)
    }
    
    func setLoading(_ isLoading: Bool) {
        walkShareButton.isEnabled = !isLoading
        closeButton.isEnabled = !isLoading
        showProfileButton.isEnabled = !isLoading
        loadingIndicator.isHidden = !isLoading
    }
    
    func formatDuration(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    func formattedDateText(from yyyyMMddOrSlash: String) -> String {
        if let d = DateFormatter.yyyyMMdd.date(from: yyyyMMddOrSlash) {
            return DateFormatter.yyyyMMddSlash.string(from: d)
        }
        return yyyyMMddOrSlash
    }
}

// MARK: - History 전용: PetProfile fetch
private extension WalkEndModalViewController {
    
    func fetchSelectedPetProfiles(
        petProfileIds: [String],
        completion: @escaping ([PetProfile]) -> Void
    ) {
        let queries = petProfileIds.map { id in
            FirestoreManager.shared.fetchQuery(
                FirestoreQuery<PetProfile>(
                    collection: .petProfile,
                    type: .document(id: id)
                )
            )
        }
        
        Single.zip(queries)
            .map { $0.flatMap { $0 } }
            .subscribe(
                onSuccess: { profiles in completion(profiles) },
                onFailure: { error in
                    print("펫프로필 조회 실패: \(error)")
                    completion([])
                }
            )
            .disposed(by: disposeBag)
    }
}

// MARK: - Alerts / Sheets / Share
private extension WalkEndModalViewController {
    
    func presentSavedAlert() {
        let alert = CustomAlertViewController(
            message: "산책이 기록되었습니다.",
            subMessage: "마이페이지에서 확인하실 수 있습니다.",
            buttons: [.init(title: "닫기", action: nil)]
        )
        present(alert, animated: true)
    }
    
    func presentSaveFailAlert(message: String) {
        let alert = CustomAlertViewController(
            message: "저장에 실패했어요.",
            subMessage: message,
            buttons: [.init(title: "확인", action: nil)]
        )
        present(alert, animated: true)
    }
    
    func presentSelectedProfilesSheet() {
        let requestViewModel = PictureUploadRequestViewModel()
        requestViewModel.output.selectedPetProfiles.accept(selectedPetProfiles)
        requestViewModel.fetchPetProfiles()
        requestViewModel.input.accept(.sender(.sherlDogResult))
        
        let nav = UINavigationController(
            rootViewController: PictureUploadRequestViewController(viewModel: requestViewModel)
        )
        
        switch selectedPetProfiles.count {
        case 1: nav.sheetPresentationController?.setModalSize(type: .onePet, grabber: true)
        case 2: nav.sheetPresentationController?.setModalSize(type: .twoPet, grabber: true)
        default: nav.sheetPresentationController?.setModalSize(type: .thrPet, grabber: true)
        }
        
        present(nav, animated: true)
    }
    
    func presentCluesFlow() {
        let day: Date = {
            switch mode {
            case let .live(_, session, _):
                return session.endDate ?? Date()
            case let .history(result, _):
                if let d = DateFormatter.yyyyMMdd.date(from: result.date) { return d }
                if let d = DateFormatter.yyyyMMddSlash.date(from: result.date) { return d }
                return Date()
            }
        }()
        
        let clueViewModel = ClueDetailViewModel(day: day)
        let clueVC = ClueDetailViewController(viewModel: clueViewModel)
        
        let nav = UINavigationController(rootViewController: clueVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        present(nav, animated: true)
    }
    /*
     func presentShareFlow() {
     let day: Date = {
     switch mode {
     case let .live(_, session, _):
     return session.endDate ?? Date()
     case let .history(result, _):
     if let d = DateFormatter.yyyyMMdd.date(from: result.date) { return d }
     if let d = DateFormatter.yyyyMMddSlash.date(from: result.date) { return d }
     return Date()
     }
     }()
     
     let clueViewModel = ClueDetailViewModel(day: day)
     
     let steps = Int(stepCountContentLabel.text ?? "") ?? 0
     let distanceKm = Double(
     (distanceContentLabel.text ?? "")
     .replacingOccurrences(of: " km", with: "")
     .trimmingCharacters(in: .whitespacesAndNewlines)
     ) ?? 0
     let distanceMeters = distanceKm * 1000
     let duration = timeContentLabel.text ?? "00:00:00"
     
     Observable.combineLatest(
     Observable.just(steps),
     Observable.just(distanceMeters),
     Observable.just(duration),
     Observable.just(day),
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
     
     let requestVM = PictureUploadRequestViewModel()
     requestVM.output.invData.accept(inv)
     requestVM.input.accept(.sender(.pictureRequest))
     
     let nav = UINavigationController(
     rootViewController: PictureUploadRequestViewController(viewModel: requestVM)
     )
     if let sheet = nav.sheetPresentationController {
     sheet.setModalSize(type: .pictureWithoutAvatar, grabber: true)
     sheet.preferredCornerRadius = 20
     }
     self.present(nav, animated: true)
     })
     .disposed(by: disposeBag)
     }
     */
}

// MARK: - UI Setup
private extension WalkEndModalViewController {
    
    func setupUI() {
        [
            backgroundImageView,
            todayLabel,
            infoBox,
            walkEndBox,
            dividerLine,
            walkShareButton,
            closeButton,
            loadingIndicator,
            mapBackgroundImageView
        ].forEach { view.addSubview($0) }
        
        infoBox.addSubviews([
            infoStack,
            infoBoxLine
        ])
        walkEndBox.addSubview(walkEndStack)
        stepLabelWrapper.addSubview(stepCountLabel)
        mapBackgroundImageView.addSubview(mapImageView)
        backgroundImageView.addSubview(todayInvPathLabel)
        
        backgroundImageView.image = .endInvestigation
        backgroundImageView.contentMode = UIScreen.isIPhoneSE ? .scaleAspectFill : .scaleAspectFit
        view.insertSubview(backgroundImageView, at: 0)
        
        infoBox.layer.borderWidth = 1
        infoBox.layer.borderColor = UIColor(named: "gray400")?.cgColor
        infoBox.layer.cornerRadius = 2
        infoBox.backgroundColor = .clear
        
        infoBoxLine.backgroundColor = UIColor(named: "gray300")
        
        walkEndBox.layer.borderWidth = 1
        walkEndBox.layer.borderColor = UIColor(named: "gray400")?.cgColor
        walkEndBox.layer.cornerRadius = 2
        walkEndBox.backgroundColor = .clear
        
        dividerLine.backgroundColor = UIColor(named: "gray400")
        
        todayLabel.textColor = UIColor(named: "keycolorPrimary2")
        todayLabel.font = (UIScreen.isIPhoneSE || UIScreen.isIPhoneMini) ? .recordTitleIsSE : .recordTitle
        
        distanceLabel.text = "거리"
        timeLabel.text = "시간"
        stepCountLabel.text = "걸음 수"
        [distanceLabel, timeLabel, stepCountLabel].forEach {
            $0.textColor = .gray500
            $0.font = .body6
        }
        
        [distanceContentLabel, timeContentLabel, stepCountContentLabel].forEach {
            $0.textColor = UIColor(named: "textSecondary")
            $0.font = .highlight3
        }
        
        distanceStack.axis = .vertical
        distanceStack.spacing = 4
        distanceStack.alignment = .leading
        distanceStack.addArrangedSubview(distanceLabel)
        distanceStack.addArrangedSubview(distanceContentLabel)
        
        timeStack.axis = .vertical
        timeStack.spacing = 4
        timeStack.alignment = .leading
        timeStack.addArrangedSubview(timeLabel)
        timeStack.addArrangedSubview(timeContentLabel)
        
        stepCountStack.axis = .vertical
        stepCountStack.spacing = 4
        stepCountStack.addArrangedSubview(stepLabelWrapper)
        stepCountStack.addArrangedSubview(stepCountContentLabel)
        
        infoStack.axis = .horizontal
        infoStack.distribution = .fillEqually
        infoStack.addArrangedSubview(distanceStack)
        infoStack.addArrangedSubview(padded(timeStack, left: 4))
        infoStack.addArrangedSubview(padded(stepCountStack, left: 12))
        
        walkEndLabel.textColor = UIColor(named: "textSecondary")
        walkEndLabel.font = .title1
        walkEndLabel.text = "멍탐정 수사 완료!"
        
        showProfileButton.setImage(UIImage(named: "showProfile"), for: .normal)
        showProfileButton.snp.makeConstraints { $0.size.equalTo(CGSize(width: 79, height: 33)) }
        
        dogImagesStack.axis = .horizontal
        dogImagesStack.spacing = -20
        dogImagesStack.alignment = .center
        
        labelAndButtonStack.axis = .horizontal
        labelAndButtonStack.spacing = 8
        labelAndButtonStack.alignment = .center
        labelAndButtonStack.addArrangedSubview(walkEndLabel)
        labelAndButtonStack.addArrangedSubview(showProfileButton)
        
        walkEndStack.axis = .horizontal
        walkEndStack.alignment = .center
        walkEndStack.spacing = 12
        walkEndStack.addArrangedSubview(dogImagesStack)
        walkEndStack.addArrangedSubview(labelAndButtonStack)
        
        todayInvPathLabel.image = UIImage(named: "todayInvPathLabel")
        
        mapBackgroundImageView.image = UIImage(named:"mapBackground")?
            .resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 16, bottom: 16, right: 16),
                            resizingMode: .stretch)
        
        mapImageView.contentMode = .scaleAspectFill
        mapImageView.clipsToBounds = true
        
        closeButton.setImage(UIImage(named: "modalExit"), for: .normal)
        
        loadingIndicator.isHidden = true
        
        setPetImages()
    }
    
    func setupConstraints() {
        if UIScreen.isIPhoneSE {
            backgroundImageView.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview()
                $0.top.bottom.equalToSuperview().offset(40)
            }
        } else {
            backgroundImageView.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview()
                $0.top.bottom.equalToSuperview()
            }
        }
        
        todayLabel.snp.makeConstraints {
            $0.top.equalTo(backgroundImageView.snp.top).offset(UIScreen.isIPhoneSE ? -10 : 70)
            $0.leading.equalTo(backgroundImageView.snp.leading).inset(45)
        }
        
        infoBox.snp.makeConstraints {
            $0.top.equalTo(todayLabel.snp.bottom).offset(UIScreen.isIPhoneSE ? 30 : 60)
            $0.leading.trailing.equalToSuperview().inset(32)
        }
        
        infoStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(12)
        }
        
        infoBoxLine.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(infoStack.snp.top).offset(50)
            $0.height.equalTo(1)
        }
        
        walkEndBox.snp.makeConstraints {
            $0.top.equalTo(infoBox.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(32)
        }
        
        walkEndStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(14)
        }
        
        dividerLine.snp.makeConstraints {
            $0.top.equalTo(walkEndBox.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(32)
            $0.height.equalTo(1)
        }
        
        todayInvPathLabel.snp.makeConstraints {
            $0.top.equalTo(dividerLine.snp.bottom).offset(15)
            $0.leading.equalToSuperview().inset(10)
        }
        
        mapBackgroundImageView.snp.makeConstraints {
            $0.top.equalTo(dividerLine.snp.bottom).offset(40)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(walkShareButton.snp.top).offset(UIScreen.isIPhoneSE ? -8 : -20)
        }
        
        mapImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(22)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(20)
        }
        
        walkShareButton.snp.makeConstraints {
            $0.height.equalTo(52)
            $0.leading.equalTo(backgroundImageView.snp.leading).inset(32)
            $0.trailing.equalTo(backgroundImageView.snp.trailing).inset(32)
            $0.bottom.equalTo(backgroundImageView.snp.bottom).inset(UIScreen.isIPhoneSE ? 95 : 130)
        }
        
        closeButton.snp.makeConstraints {
            $0.top.equalTo(todayLabel.snp.bottom).offset(UIScreen.isIPhoneSE ? 40 : 30)
            $0.trailing.equalToSuperview().inset(32)
            $0.size.equalTo(28)
        }
        
        loadingIndicator.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        stepCountLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

// MARK: - Helpers
private extension WalkEndModalViewController {
    
    func setPetImages() {
        dogImagesStack.arrangedSubviews.forEach {
            dogImagesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        dogImagesStack.spacing = selectedPetProfiles.count > 1 ? -20 : 0
        
        if selectedPetProfiles.isEmpty {
            // 기본 이미지 (선택된 강아지가 없을 때)
            [UIImage.sampleDog, .sampleDog, .sampleDog].forEach { img in
                let iv = UIImageView(image: img)
                iv.contentMode = .scaleAspectFill
                iv.clipsToBounds = true
                iv.layer.cornerRadius = 16
                iv.snp.makeConstraints { $0.size.equalTo(32) }
                dogImagesStack.addArrangedSubview(iv)
            }
            return
        }
        
        selectedPetProfiles.forEach { profile in
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 16
            imageView.layer.borderColor = UIColor(named: "textInverse")?.cgColor
            imageView.layer.borderWidth = 1
            imageView.snp.makeConstraints { $0.size.equalTo(32) }
            
            if let url = URL(string: profile.image) {
                let processor = DownsamplingImageProcessor(size: CGSize(width: 100, height: 100))
                imageView.kf.indicatorType = .activity
                KF.url(url)
                    .placeholder(UIImage.petAvatar)
                    .setProcessor(processor)
                    .cacheOriginalImage()
                    .fade(duration: 0.25)
                    .onFailureImage(UIImage.petAvatar)
                    .set(to: imageView)
            }
            
            dogImagesStack.addArrangedSubview(imageView)
        }
    }
    
    func addVerticalSeparators() {
        infoBox.layoutIfNeeded()
        
        let totalWidth = infoBox.bounds.width
        let sectionCount = infoStack.arrangedSubviews.count
        guard sectionCount > 1 else { return }
        
        let sectionWidth = totalWidth / CGFloat(sectionCount)
        
        for i in 1..<sectionCount {
            let xPos = sectionWidth * CGFloat(i)
            let line = CALayer()
            line.frame = CGRect(
                x: xPos,
                y: 0,
                width: 1,
                height: infoBox.bounds.height
            )
            line.backgroundColor = UIColor(named: "gray300")?.cgColor
            line.name = "vLine"
            infoBox.layer.addSublayer(line)
        }
    }
    
    private func padded(_ view: UIView, left: CGFloat) -> UIView {
        let wrapper = UIView()
        wrapper.addSubview(view)
        wrapper.layoutMargins = UIEdgeInsets(top: 0, left: left, bottom: 0, right: 0)
        wrapper.preservesSuperviewLayoutMargins = true
        
        view.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(wrapper.layoutMarginsGuide.snp.leading)
            make.trailing.equalToSuperview()
        }
        return wrapper
    }
}
