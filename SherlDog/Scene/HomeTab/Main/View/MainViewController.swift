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
    
    private let requestViewModel = PictureUploadRequestViewModel()
    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()
    private lazy var viewModel = MainViewModel(locationManager: locationManager)
    private var input: MainViewModel.Input { viewModel.input }
    private var output: MainViewModel.Output { viewModel.output }
    private var hasSetInitialCamera = false
    
    private var pathRenderer: PathRenderer!
    private var clueMarkerRenderer: ClueMarkerRenderer!
    
    // 지도 배경
    private let mapView = NMFMapView()
    
    // 상단 기록 뷰
    private let statusView = UIView()
    
    // 거리(m), 시간(분), 걸음 수, 강아지 이미지, 멍탕점과 함께 수사 중
    private let distanceLabel = UILabel()
    private let timeLabel = UILabel()
    private let stepsLabel = UILabel()
    private var selectedPetImage
    : [String] = ["sampleDogImage", "sampleDogImage", "sampleDogImage"]
    private let statusLabel = UILabel()
    
    // distance, time, steps
    private let distanceValueLabel = UILabel()
    private let trackingTimeLabel
    = UILabel()
    private let stepCountLabel
    = UILabel()
    
    // 스택 뷰
    private let titleStack = UIStackView()
    private let valueStack = UIStackView()
    private let statusStack = UIStackView()
    private let detectiveImageStack = UIStackView()
    
    // 버튼
    private let endButton = UIButton()
    private let clueButton = UIButton()
    private let walkStartButton = UIButton()
    private let locationButton = UIButton()
    
    // 거리 측정 함수 뷰모델
    private let dataTrackingViewModel = DataTrackingViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        requestLocationAuthorization()
    }
    
    private func requestLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            setupMapAndStartLocation()
        case .denied, .restricted:
            showLocationSettingsAlert()
        @unknown default:
            break
        }
    }
    // 위치권한을 거부 했을때
    private func showLocationSettingsAlert() {
        let alert = CustomAlertViewController(
            message: "위치 권한을 '항상 허용'으로\n설정해주세요",
            subMessage: "화면이 꺼져도 산책 경로를 기록 할 수 있어요.\n경로 기록 이외의 목적으로는\n사용되지 않아요",
            buttons: [
                CustomAlertViewController.AlertButton(
                    title: "취소",
                    action: nil
                ),
                CustomAlertViewController.AlertButton(
                    title: "설정으로 이동",
                    action: {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                           UIApplication.shared.canOpenURL(settingsURL) {
                            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                        }
                    }
                )
            ]
        )
        self.present(alert, animated: true)
    }
    
    /// 위치 권한이 '사용 중'일 때 '항상 허용' 권장 안내
    private func checkAndGuideAlwaysAuthorizationIfNeeded() {
        let status = locationManager.authorizationStatus
        
        // 이미 Always 허용이면 패스
        guard status == .authorizedWhenInUse else { return }
        
        // 사용 중 허용인 경우만 항상 허용을 유도
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            let alert = CustomAlertViewController(
                message: "위치 권한을 '항상 허용'으로\n설정해주세요",
                subMessage: "화면이 꺼져도 산책 경로를 기록 할 수 있어요.\n경로 기록 이외의 목적으로는\n사용되지 않아요",
                buttons: [
                    CustomAlertViewController.AlertButton(
                        title: "취소",
                        action: nil
                    ),
                    CustomAlertViewController.AlertButton(
                        title: "설정으로 이동",
                        action: {
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                               UIApplication.shared.canOpenURL(settingsURL) {
                                UIApplication.shared.open(settingsURL)
                            }
                        }
                    )
                ]
            )
            self.present(alert, animated: true)
        }
    }
    
    private func setupMapAndStartLocation() {
        locationManager.startUpdatingLocation()
        
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
        trackingBind()
        configureInitialVisibility()
        loadSavedClues()
        
        requestViewModel.fetchPetProfiles()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        loadSavedClues()
        requestViewModel.fetchPetProfiles()
    }
    
    // 저장된 단서들을 Firebase에서 불러와서 마커로 표시
    private func loadSavedClues() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        // 기존 단서 마커들 제거
        clueMarkerRenderer.clear()
        
        // Firestore에서 내 단서들 가져오기
        FirestoreManager.shared.fetchQuery(FirestoreQuery<ClueModel>(
            collection: .clues,
            type: .whereField(field: "userId", value: userId)
            
        )
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] myClues in
                if myClues.isEmpty {
                    print("저장된 단서가 없습니다")
                } else {
                    self?.clueMarkerRenderer.render(clues: myClues)                }
            },
            onFailure: { error in
                print("단서 불러오기 실패: \(error.localizedDescription)")
            }
        )
        .disposed(by: disposeBag)
    }
    
    private func trackingBind() {
        dataTrackingViewModel.numberOfSteps
            .map { "\($0)" }
            .bind(to: stepCountLabel
                .rx.text)
            .disposed(by: disposeBag)
        
        dataTrackingViewModel.distance
            .map { String(format: "%.2f", $0 / 1000.0) }
            .bind(to: distanceValueLabel.rx.text)
            .disposed(by: disposeBag)
        
        dataTrackingViewModel.trackingActive
            .filter { $0 }
            .flatMapLatest { _ in
                Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
                    .take(until: self.dataTrackingViewModel.trackingActive.filter { !$0 })
                    .withLatestFrom(self.dataTrackingViewModel.startDate)
                    .compactMap { $0 }
                    .map { start in
                        let interval = Int(Date().timeIntervalSince(start))
                        let hours = interval / 3600
                        let minutes = (interval % 3600) / 60
                        let seconds = interval % 60
                        let text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                        return text
                    }
            }
            .bind(to: trackingTimeLabel
                .rx.text)
            .disposed(by: disposeBag)
    }
    
    private func bind() {
        output.fullSideOfCourse
            .subscribe(onNext: { [weak self] fullSide in
                guard let self else { return }
                
                // If not enough path, show alert and return
                if fullSide.isEmpty {
                    let alert = CustomAlertViewController(
                        message: "수사를 종료하시겠습니까?",
                        subMessage: "5미터 이하의 경로는 기록이 되지 않아요",
                        buttons: [CustomAlertViewController.AlertButton(title: "확인", action:
                                                                            {
                                                                                let confirmAlert = CustomAlertViewController(
                                                                                    message: "수사가 종료되었습니다.",
                                                                                    subMessage: nil,
                                                                                    buttons: [CustomAlertViewController.AlertButton(title: "확인", action: nil)]
                                                                                    
                                                                                )
                                                                                self.present(confirmAlert, animated: true)
                                                                                self.setInvestigation(active: false)
                                                                            }),CustomAlertViewController.AlertButton(title: "취소", action: nil)])
                    
                    self.present(alert, animated: true)
                    return
                }
                
                // WalkendModalViewController의 imageView에 맞게 들어가도록 예측한 값.
                /*
                 top 25추정 + 박스사이즈(약 120추정) + 15 + 박스사이즈(약 150추정) + 60 + 라벨사이즈(약 24추정) + 75 = 469
                 bottom 140 + 버튼사이즈(52) + 24추정(이미지뷰는 아래 버튼에 -12로 걸려있고, 아래 버튼은 이미지 뷰에 24로 걸려있음) = 216
                 합 약 685
                 paddingInsets의 top, bottom을 300씩 줘 여유공간 85, top, bottom 각각 42정도 확보
                 leading, trailing도 비슷한 수준의 여유공간 50을 설정
                 */
                let paddingInset = UIEdgeInsets(top: 300, left: 50, bottom: 300, right: 50)
                let cameraUpdate = NMFCameraUpdate(fit: fullSide, paddingInsets: paddingInset)
                cameraUpdate.animation = .easeIn
                self.mapView.moveCamera(cameraUpdate)
                
                // 설정된 animationDuration에 0.1초의 여유시간을 주고 그 이후에 코드가 실행되도록 설정
                let duration = max(self.mapView.animationDuration, cameraUpdate.animationDuration) + 0.1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    if let window = self.view.window {
                        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
                        let image = renderer.image { ctx in
                            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                        }
                        
                        let selectedProfiles = self.requestViewModel.output.selectedPetProfiles.value
                        let walkEndModal = WalkEndModalViewController(dataTrackingViewModel: self.dataTrackingViewModel, selectedProfiles: selectedProfiles)
                        let nav = UINavigationController(rootViewController: walkEndModal)
                        nav.modalPresentationStyle = .overFullScreen
                        self.present(nav, animated: true) {
                            self.dataTrackingViewModel.fullScreenImage.accept(image)
                        }
                    }
                    
                    self.pathRenderer.clear()
                    self.setInvestigation(active: false)
                }
            })
            .disposed(by: disposeBag)
        
        output.coordinates
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] coords in
                self?.pathRenderer.render(coords: coords)
            })
            .disposed(by: disposeBag)
        
        requestViewModel.output.petIndex.subscribe(onNext: { [ weak self ] index in
            self?.viewModel.input.startTracking.accept(())
            self?.dataTrackingViewModel.startTracking()
            self?.setInvestigation(active: true)
        })
        .disposed(by: disposeBag)
    }
    
    private func inputBind() {
        
        self.clueButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                PermissionManager.requestPermission(type: .camera) { [weak self] isAllowed in
                    guard let self else { return }

                    guard isAllowed else {
                        let alert = CustomAlertViewController(
                            message: "카메라 권한이 필요합니다.",
                            subMessage: "설정에서 변경해주세요.",
                            buttons: [
                                CustomAlertViewController.AlertButton(
                                    title: "취소",
                                    action: nil
                                ),
                                CustomAlertViewController.AlertButton(
                                    title: "설정으로 이동",
                                    action: {
                                        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                                           UIApplication.shared.canOpenURL(settingsURL) {
                                            UIApplication.shared.open(
                                                settingsURL,
                                                options: [:],
                                                completionHandler: nil
                                            )
                                        }
                                    }
                                )
                            ]
                        )
                        self.present(alert, animated: true)
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
        
        self.endButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let alert = CustomAlertViewController(
                    message: "수사를 종료하시겠습니까?",
                    subMessage: nil,
                    buttons: [
                        CustomAlertViewController.AlertButton(title: "확인", action: {
                            self.dataTrackingViewModel.stopTracking()
                            self.viewModel.input.stopTracking.accept(())
                        }),
                        CustomAlertViewController.AlertButton(title: "취소", action: nil)
                    ]
                )
                self.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
        
        self.walkStartButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
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
        
        self.locationButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self, let currentLocation = self.locationManager.location else { return }
                let coord = currentLocation.coordinate
                let target = NMGLatLng(lat: coord.latitude, lng: coord.longitude)
                let cameraUpdate = NMFCameraUpdate(scrollTo: target)
                cameraUpdate.animation = .easeIn
                self.mapView.moveCamera(cameraUpdate)
            })
            .disposed(by: disposeBag)
        
        requestViewModel.output.selectedPetProfiles
            .subscribe(onNext: { [weak self] selectedProfiles in
                guard let self = self else { return }
                
                // 선택된 강아지들의 이미지로 배열 업데이트
                if !selectedProfiles.isEmpty {
                    self.selectedPetImage
                    = selectedProfiles.map { $0.image }
                    self.updateDetectiveImageStack()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func updateDetectiveImageStack() {
        // 기존 이미지뷰들 제거
        detectiveImageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        detectiveImageStack.spacing = selectedPetImage
            .count > 1 ? -8 : 0
        
        selectedPetImage
            .forEach { imageName in
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 18
                imageView.layer.borderColor = UIColor(named: "textInverse")?.cgColor
                imageView.layer.borderWidth = 1
                imageView.snp.makeConstraints { $0.size.equalTo(36) }
                
                // URL인지 확인해서 이미지 로드
                if imageName.hasPrefix("http"), let url = URL(string: imageName) {
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
                } else {
                    imageView.image = UIImage(named: imageName)
                }
                detectiveImageStack.addArrangedSubview(imageView)
            }
        // 텍스트도 업데이트
        statusLabel.text = selectedPetImage
            .count > 1 ? "멍탐정들과 함께 수사 중" : "멍탐정과 함께 수사 중"
    }
    
    //    private func showWalkEndModal() {
    //        let selectedProfiles = requestViewModel.output.selectedPetProfiles.value
    //        let walkEndModal = WalkEndModalViewController(viewModel: trackingViewModel, selectedProfiles: selectedProfiles)
    //        let nav = UINavigationController(rootViewController: walkEndModal)
    //        nav.modalPresentationStyle = .overFullScreen
    //        present(nav, animated: true)
    //    }
    
    private func configureInitialVisibility() {
        // 시작 시 상태 뷰 및 버튼 숨김
        statusView.isHidden = true
        clueButton.isHidden = true
        endButton.isHidden = true
    }
    
    private func setInvestigation(active: Bool) {
        hasSetInitialCamera = false
        statusView.isHidden = !active
        clueButton.isHidden = !active
        endButton.isHidden = !active
        walkStartButton.isHidden = active
        
        if !active {
            distanceValueLabel.text = "0.00"
            trackingTimeLabel
                .text = "00:00:00"
            stepCountLabel
                .text = "0"
        }
    }
    
    private func setupUI() {
        // 현재위치 아이콘 설정
        mapView.positionMode = .normal
        
        let locationOverlay = mapView.locationOverlay
        let overlayImage = NMFOverlayImage(name: "locationImage")
        locationOverlay.icon = overlayImage
        locationOverlay.iconWidth = 46
        locationOverlay.iconHeight = 46
        
        // statusView 설정
        statusView.backgroundColor = .gray50
        statusView.layer.cornerRadius = 16
        statusView.layer.borderWidth = 1
        statusView.layer.borderColor = UIColor(named: "gray200")?.cgColor
        
        // titleStack 설정
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
        
        // ValueStack 설정
        [distanceValueLabel, trackingTimeLabel
         , stepCountLabel
        ].forEach {
            $0.textAlignment = .center
            $0.font = .highlight3
            $0.textColor = .textPrimary
        }
        
        valueStack.axis = .horizontal
        valueStack.distribution = .fillEqually
        
        // detectiveImageStack 설정
        detectiveImageStack.axis = .horizontal
        detectiveImageStack.alignment = .center
        
        // StatusStack 설정
        statusLabel.text = "멍탐정과 함께 수사 중"
        statusLabel.textAlignment = .center
        statusLabel.font = .body2
        statusLabel.textColor = .textPrimary
        statusStack.axis = .horizontal
        statusStack.spacing = 8
        statusStack.alignment = .center
        statusStack.distribution = .fill
        
        // 버튼 설정
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
        
        [distanceValueLabel, trackingTimeLabel
         , stepCountLabel
        ].forEach { valueStack.addArrangedSubview($0) }
        
        [distanceLabel, timeLabel, stepsLabel].forEach { titleStack.addArrangedSubview($0) }
        
        [detectiveImageStack, statusLabel].forEach { statusStack.addArrangedSubview($0) }
        
        // 스택 + 상태 넣기
        [titleStack, valueStack, statusStack].forEach { statusView.addSubview($0) }
        
        
        [mapView, statusView, endButton, clueButton, walkStartButton, locationButton].forEach {
            view.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        mapView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        statusView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(136) // estimated height
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

extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let coord = location.coordinate
        mapView.locationOverlay.location = NMGLatLng(lat: coord.latitude, lng: coord.longitude)
        
        // 앱 처음 시작 시 한 번만 현재 위치로 카메라 이동
        if !hasSetInitialCamera {
            let coord = location.coordinate
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
            showLocationSettingsAlert()
        default:
            break
        }
    }
}
