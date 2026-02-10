//
//  MainViewController.swift
//  SherlDog
//
//  Created by 김재우 on 6/5/25.
//

import UIKit
import SnapKit
import NMapsMap
import RxCocoa
import RxSwift
import RxCoreLocation
import CoreLocation
import FirebaseAuth
import Kingfisher

class MainViewController: UIViewController {
    
    //Dependencies
    private let requestViewModel = PictureUploadRequestViewModel()
    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()
    
    private lazy var viewModel = MainViewModel(locationManager: locationManager)
    private var input: MainViewModel.Input { viewModel.input }
    private var output: MainViewModel.Output { viewModel.output }
    
    //State
    private var hasSetInitialCamera = false
    private var didSetup = false
    
    //Renderers
    private var pathRenderer: PathRenderer!
    private var clueMarkerRenderer: ClueMarkerRenderer!
    
    // MARK: - UI
    // UI: Map
    private let mapView = NMFMapView()
    
    // UI: Top Status
    private let statusView = UIView()
    
    private let distanceLabel = UILabel()
    private let timeLabel = UILabel()
    private let stepsLabel = UILabel()
    
    private let statusLabel = UILabel()
    private let distanceValueLabel = UILabel()
    private let trackingTimeLabel = UILabel()
    private let stepCountLabel = UILabel()
    
    // UI: Stacks
    private let titleStack = UIStackView()
    private let valueStack = UIStackView()
    private let statusStack = UIStackView()
    private let detectiveImageStack = UIStackView()
    
    private var selectedPetImage: [String] = ["sampleDogImage", "sampleDogImage", "sampleDogImage"]
    
    // UI: Buttons
    private let endButton = UIButton()
    private let clueButton = UIButton()
    private let walkStartButton = UIButton()
    private let locationButton = UIButton()
    
    // 그라디언트 레이어
    private let gradientLayer = CAGradientLayer()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLocationManager()
        requestLocationAuthorization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        input.reloadClues.accept(())
        requestViewModel.fetchPetProfiles()
    }
}
// MARK: - Setup & Permissions
private extension MainViewController {
    
    func configureLocationManager() {
        locationManager.delegate = self
    }
    
    func requestLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            setupMapAndStartLocation()
        case .denied, .restricted:
            presentLocationSettingsAlert()
        @unknown default:
            break
        }
    }
    
    func checkAndGuideAlwaysAuthorizationIfNeeded() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.presentLocationSettingsAlert()
        }
    }
    
    func setupMapAndStartLocation() {
        guard !didSetup else { return }
        didSetup = true
        
        pathRenderer = PathRenderer(mapView: mapView)
        
        clueMarkerRenderer = ClueMarkerRenderer(mapView: mapView)
        clueMarkerRenderer.onTapMarker = { [weak self] clue in
            guard let self else { return }
            let vm = ClueDetailViewModel(clue: clue)
            let detailVC = ClueDetailViewController(viewModel: vm)
            detailVC.modalPresentationStyle = .pageSheet
            detailVC.sheetPresentationController?.setModalSize(type: .clue, grabber: true)
            self.present(detailVC, animated: true)
        }
        
        setupUI()
        setupConstraints()
        bind()
        inputBind()
        configureInitialVisibility()
        
        input.reloadClues.accept(())
        
        requestViewModel.fetchPetProfiles()
    }
}

// MARK: - Bindings
private extension MainViewController {
    
    func bind() {
        output.fullSideOfCourse
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] bounds in
                self?.handleSessionDidStop(bounds: bounds)
            })
            .disposed(by: disposeBag)
        
        output.sessionState
            .map { $0.coordinates }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] coords in
                self?.pathRenderer.render(coords: coords)
            })
            .disposed(by: disposeBag)
        
        output.clues
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] clues in
                guard let self else { return }
                self.clueMarkerRenderer.clear()
                if !clues.isEmpty {
                    self.clueMarkerRenderer.render(clues: clues)
                }
            })
            .disposed(by: disposeBag)
        
        requestViewModel.output.petIndex
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                self.input.startTracking.accept(())
                self.setInvestigation(active: true)
            })
            .disposed(by: disposeBag)
        
        bindMetrics()
    }
    
    func bindMetrics() {
        output.sessionState
            .map { "\($0.steps)" }
            .bind(to: stepCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.sessionState
            .map { String(format: "%.2f", $0.distanceMeters / 1000.0) }
            .bind(to: distanceValueLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.sessionState
            .map { state -> String in
                let s = state.elapsedSeconds
                let h = s / 3600
                let m = (s % 3600) / 60
                let sec = s % 60
                return String(format: "%02d:%02d:%02d", h, m, sec)
            }
            .bind(to: trackingTimeLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    func inputBind() {
        bindClueButton()
        bindEndButton()
        bindWalkStartButton()
        bindLocationButton()
        bindSelectedPetProfiles()
    }
}

// MARK: - Button Bindings
private extension MainViewController {
    
    func bindClueButton() {
        clueButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                
                PermissionManager.requestPermission(type: .camera) { [weak self] isAllowed in
                    guard let self else { return }
                    
                    guard isAllowed else {
                        self.presentCameraSettingsAlert()
                        return
                    }
                    
                    guard let currentLocation = self.locationManager.location else { return }
                    
                    self.clueMarkerRenderer.addTemporaryMarker(
                        latitude: currentLocation.coordinate.latitude,
                        longitude: currentLocation.coordinate.longitude
                    ) { [weak self] in
                        guard let self else { return }
                        let viewModel = ClueDetailViewModel(coordinate: currentLocation.coordinate)
                        let detailVC = ClueDetailViewController(viewModel: viewModel)
                        let nav = UINavigationController(rootViewController: detailVC)
                        nav.modalPresentationStyle = .pageSheet
                        nav.sheetPresentationController?.setModalSize(type: .clue, grabber: true)
                        self.present(nav, animated: true)
                    }
                    
                    let cameraViewModel = CameraViewModel()
                    cameraViewModel.input.accept(.sender(.clueLeave))
                    cameraViewModel.markerLocation = currentLocation.coordinate
                    
                    let cameraView = UINavigationController(
                        rootViewController: CameraViewController(viewModel: cameraViewModel)
                    )
                    cameraView.modalPresentationStyle = .fullScreen
                    self.present(cameraView, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func bindEndButton() {
        endButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                self.presentEndInvestigationConfirm { [weak self] in
                    self?.input.stopTracking.accept(())
                }
            })
            .disposed(by: disposeBag)
    }
    
    func bindWalkStartButton() {
        walkStartButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                
                self.requestViewModel.fetchPetProfiles()
                self.requestViewModel.input.accept(.sender(.sherlDogRequest))
                let requestView = PictureUploadRequestViewController(viewModel: self.requestViewModel)
                requestView.modalPresentationStyle = .pageSheet
                
                let petCount = self.requestViewModel.output.petProfiles.value.count
                switch petCount {
                case 1: requestView.sheetPresentationController?.setModalSize(type: .onePet, grabber: true)
                case 2: requestView.sheetPresentationController?.setModalSize(type: .twoPet, grabber: true)
                case 3: requestView.sheetPresentationController?.setModalSize(type: .thrPet, grabber: true)
                default: requestView.sheetPresentationController?.setModalSize(type: .thrPet, grabber: true)
                }
                
                self.present(requestView, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    func bindLocationButton() {
        locationButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self,
                      let currentLocation = self.locationManager.location else { return }
                
                let coord = currentLocation.coordinate
                let target = NMGLatLng(lat: coord.latitude, lng: coord.longitude)
                let cameraUpdate = NMFCameraUpdate(scrollTo: target)
                cameraUpdate.animation = .easeIn
                self.mapView.moveCamera(cameraUpdate)
            })
            .disposed(by: disposeBag)
    }
    
    func bindSelectedPetProfiles() {
        requestViewModel.output.selectedPetProfiles
            .subscribe(onNext: { [weak self] selectedProfiles in
                guard let self else { return }
                
                if !selectedProfiles.isEmpty {
                    self.selectedPetImage = selectedProfiles.map { $0.image }
                    self.updateDetectiveImageStack()
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UI Updates
private extension MainViewController {
    
    func updateDetectiveImageStack() {
        detectiveImageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        detectiveImageStack.spacing = selectedPetImage.count > 1 ? -8 : 0
        
        selectedPetImage.forEach { imageName in
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 18
            imageView.layer.borderColor = UIColor(named: "textInverse")?.cgColor
            imageView.layer.borderWidth = 1
            imageView.snp.makeConstraints { $0.size.equalTo(36) }
            
            if imageName.hasPrefix("http"), let url = URL(string: imageName) {
                let processor = DownsamplingImageProcessor(size: CGSize(width: 100, height: 100))
                imageView.kf.indicatorType = .activity
                KF.url(url)
                    .placeholder(UIImage.petAvatar)
                    .setProcessor(processor)
                    .cacheOriginalImage()
                    .fade(duration: 0.25)
                    .onFailureImage(UIImage.petAvatar)
                    .set(to: imageView)
            } else {
                imageView.image = UIImage(named: imageName)
            }
            
            detectiveImageStack.addArrangedSubview(imageView)
        }
        
        statusLabel.text = selectedPetImage.count > 1 ? "멍탐정들과 함께 수사 중" : "멍탐정과 함께 수사 중"
    }
    
    func configureInitialVisibility() {
        statusView.isHidden = true
        gradientLayer.isHidden = true
        clueButton.isHidden = true
        endButton.isHidden = true
    }
    
    func setInvestigation(active: Bool) {
        hasSetInitialCamera = false
        statusView.isHidden = !active
        gradientLayer.isHidden = !active
        clueButton.isHidden = !active
        endButton.isHidden = !active
        walkStartButton.isHidden = active
        
        if !active {
            distanceValueLabel.text = "0.00"
            trackingTimeLabel.text = "00:00:00"
            stepCountLabel.text = "0"
        }
    }
}

// MARK: - UI Setup
private extension MainViewController {
    
    func setupUI() {
        mapView.positionMode = .normal
        
        let locationOverlay = mapView.locationOverlay
        let overlayImage = NMFOverlayImage(name: "locationImage")
        locationOverlay.icon = overlayImage
        locationOverlay.iconWidth = 46
        locationOverlay.iconHeight = 46
        
        statusView.backgroundColor = .gray50
        statusView.layer.cornerRadius = 16
        statusView.layer.borderWidth = 1
        statusView.layer.borderColor = UIColor(named: "gray200")?.cgColor
        
        [distanceLabel, timeLabel, stepsLabel].forEach {
            $0.textAlignment = .center
            $0.font = .body5
            $0.textColor = .textDisabled
        }
        distanceLabel.text = "거리(km)"
        timeLabel.text = "시간"
        stepsLabel.text = "걸음 수"
        
        titleStack.axis = .horizontal
        titleStack.distribution = .fillEqually
        
        [distanceValueLabel, trackingTimeLabel, stepCountLabel].forEach {
            $0.textAlignment = .center
            $0.font = .highlight3
            $0.textColor = .textPrimary
        }
        
        valueStack.axis = .horizontal
        valueStack.distribution = .fillEqually
        
        // gradientLayer 설정
        mapView.layer.addSublayer(gradientLayer)
        
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(1).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.startPoint = .init(x: 0.5, y: 0.0)
        gradientLayer.endPoint = .init(x: 0.5, y: 0.3)
        
        // detectiveImageStack 설정
        detectiveImageStack.axis = .horizontal
        detectiveImageStack.alignment = .center
        
        statusLabel.text = "멍탐정과 함께 수사 중"
        statusLabel.textAlignment = .center
        statusLabel.font = .body2
        statusLabel.textColor = .textPrimary
        
        statusStack.axis = .horizontal
        statusStack.spacing = 8
        statusStack.alignment = .center
        statusStack.distribution = .fill
        
        clueButton.setTitle("단서 남기기", for: .normal)
        clueButton.setTitleColor(.textInverse, for: .normal)
        clueButton.backgroundColor = .textInverse
        clueButton.titleLabel?.font = .highlight4
        clueButton.setTitleColor(UIColor(named: "keycolorPrimary3"), for: .normal)
        clueButton.layer.borderWidth = 1
        clueButton.layer.borderColor = UIColor(named: "keycolorPrimary3")?.cgColor
        clueButton.layer.cornerRadius = 6
        
        endButton.setTitle("수사 종료하기", for: .normal)
        endButton.setTitleColor(UIColor(named: "textInverse"), for: .normal)
        endButton.backgroundColor = .keycolorPrimary3
        endButton.titleLabel?.font = .highlight4
        endButton.layer.cornerRadius = 6
        
        walkStartButton.setTitle("수사 시작하기", for: .normal)
        walkStartButton.setTitleColor(UIColor(named: "textInverse"), for: .normal)
        walkStartButton.titleLabel?.font = UIFont.highlight4
        walkStartButton.backgroundColor = UIColor(named: "keycolorPrimary3")
        walkStartButton.layer.cornerRadius = 6
        
        locationButton.setImage(UIImage(named: "locationButton"), for: .normal)
        
        [distanceValueLabel, trackingTimeLabel, stepCountLabel].forEach { valueStack.addArrangedSubview($0) }
        [distanceLabel, timeLabel, stepsLabel].forEach { titleStack.addArrangedSubview($0) }
        [detectiveImageStack, statusLabel].forEach { statusStack.addArrangedSubview($0) }
        
        [titleStack, valueStack, statusStack].forEach { statusView.addSubview($0) }
        [mapView, statusView, endButton, clueButton, walkStartButton, locationButton].forEach { view.addSubview($0) }
    }
    
    func setupConstraints() {
        mapView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        statusView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(136)
        }
        
        titleStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        valueStack.snp.makeConstraints {
            $0.top.equalTo(titleStack.snp.bottom).offset(18)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        statusStack.snp.makeConstraints {
            $0.top.equalTo(valueStack.snp.bottom).offset(12)
            $0.bottom.equalToSuperview().inset(10)
            $0.centerX.equalToSuperview()
        }
        
        clueButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.trailing.equalTo(view.snp.centerX).offset(-8)
            $0.height.equalTo(52)
        }
        
        endButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(clueButton)
            $0.leading.equalTo(view.snp.centerX).offset(8)
            $0.height.equalTo(52)
        }
        
        walkStartButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            $0.height.equalTo(52)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        locationButton.snp.makeConstraints {
            $0.size.equalTo(48)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(walkStartButton.snp.top).offset(-16)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MainViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let coord = location.coordinate
        mapView.locationOverlay.location = NMGLatLng(lat: coord.latitude, lng: coord.longitude)
        
        if !hasSetInitialCamera {
            let target = NMGLatLng(lat: coord.latitude, lng: coord.longitude)
            let cameraUpdate = NMFCameraUpdate(scrollTo: target)
            cameraUpdate.animation = .none
            mapView.moveCamera(cameraUpdate)
            mapView.zoomLevel = 16.0
            hasSetInitialCamera = true
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            setupMapAndStartLocation()
            checkAndGuideAlwaysAuthorizationIfNeeded()
        case .denied, .restricted:
            presentLocationSettingsAlert()
        default:
            break
        }
    }
}

// MARK: - Alerts
private extension MainViewController {
    
    func presentLocationSettingsAlert() {
        let alert = CustomAlertViewController(
            message: "위치 권한을 '항상 허용'으로\n설정해주세요",
            subMessage: "화면이 꺼져도 산책 경로를 기록 할 수 있어요.\n경로 기록 이외의 목적으로는\n사용되지 않아요",
            buttons: [
                .init(title: "취소", action: nil),
                .init(title: "설정으로 이동", action: { self.openAppSettings() })
            ]
        )
        present(alert, animated: true)
    }
    
    func presentCameraSettingsAlert() {
        let alert = CustomAlertViewController(
            message: "카메라 권한이 필요합니다.",
            subMessage: "설정에서 변경해주세요.",
            buttons: [
                .init(title: "취소", action: nil),
                .init(title: "설정으로 이동", action: { self.openAppSettings() })
            ]
        )
        present(alert, animated: true)
    }
    
    func presentEndInvestigationConfirm(onConfirm: @escaping () -> Void) {
        let alert = CustomAlertViewController(
            message: "수사를 종료하시겠습니까?",
            subMessage: nil,
            buttons: [
                .init(title: "확인", action: onConfirm),
                .init(title: "취소", action: nil)
            ]
        )
        present(alert, animated: true)
    }
    
    func presentTooShortPathAlert(onConfirm: @escaping () -> Void) {
        let alert = CustomAlertViewController(
            message: "수사를 종료하시겠습니까?",
            subMessage: "5미터 이하의 경로는 기록이 되지 않아요",
            buttons: [
                .init(title: "확인", action: onConfirm),
                .init(title: "취소", action: nil)
            ]
        )
        present(alert, animated: true)
    }
    
    func presentInvestigationEndedAlert() {
        let confirmAlert = CustomAlertViewController(
            message: "수사가 종료되었습니다.",
            subMessage: nil,
            buttons: [.init(title: "확인", action: nil)]
        )
        present(confirmAlert, animated: true)
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

// MARK: - Walk End Flow
private extension MainViewController {
    
    func handleSessionDidStop(bounds: NMGLatLngBounds) {
        guard !bounds.isEmpty else {
            presentTooShortPathAlert { [weak self] in
                self?.presentInvestigationEndedAlert()
                self?.setInvestigation(active: false)
            }
            return
        }
        
        moveCameraToFit(bounds: bounds) { [weak self] in
            guard let self else { return }
            self.captureAndPresentWalkEnd()
            self.pathRenderer.clear()
            self.setInvestigation(active: false)
        }
    }
    
    func moveCameraToFit(bounds: NMGLatLngBounds, completion: @escaping () -> Void) {
        let paddingInset = UIEdgeInsets(top: 300, left: 50, bottom: 300, right: 50)
        let cameraUpdate = NMFCameraUpdate(fit: bounds, paddingInsets: paddingInset)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
        
        let delay = max(mapView.animationDuration, cameraUpdate.animationDuration) + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: completion)
    }
    
    func captureAndPresentWalkEnd() {
        guard let screenshot = captureScreen() else { return }
        
        let selectedProfiles = requestViewModel.output.selectedPetProfiles.value
        let session = output.sessionState.value   //MainVM에서 받은 스냅샷
        
        let walkEndModal = WalkEndModalViewController(
            screenshot: screenshot,
            session: session,
            selectedProfiles: selectedProfiles,
            viewModel: WalkResultViewModel()
        )
        
        let nav = UINavigationController(rootViewController: walkEndModal)
        nav.modalPresentationStyle = .overFullScreen
        present(nav, animated: true)
    }
    
    func captureScreen() -> UIImage? {
        guard let window = view.window else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }
}
