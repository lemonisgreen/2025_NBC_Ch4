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

class MainViewController: UIViewController, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()
    private let viewModel = MainViewModel()
    private var hasSetInitialCamera = false
    
    // 지도 배경
    private let mapView = NMFMapView()

    // 상단 기록 뷰
    private let statusView = UIView()
    
    // 거리(m), 시간(분), 걸음 수, 강아지 이미지, 멍탕점과 함께 수사 중
    private let distanceLabel = UILabel()
    private let timeLabel = UILabel()
    private let stepsLabel = UILabel()
    private let image: [String] = []
    private let statusLabel = UILabel()
    
    // distance, time, steps
    private let distance = UILabel()
    private let time = UILabel()
    private let steps = UILabel()
    
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
    private let DataTrackingVM = DataTrackingViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.distanceFilter = 5
        locationManager.startUpdatingLocation()
        setupUI()
        setupConstraints()
        bind()
        inputBind()
        configureInitialVisibility()
    }
    
    private func bind() {
        DataTrackingVM.numberOfSteps
            .map { "\($0)" }
            .bind(to: steps.rx.text)
            .disposed(by: disposeBag)

        DataTrackingVM.distance
            .map { String(format: "%.2f", $0 / 1000.0) }
            .bind(to: distance.rx.text)
            .disposed(by: disposeBag)

        DataTrackingVM.trackingActive
            .filter { $0 }
            .flatMapLatest { _ in
                Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
                    .take(until: self.DataTrackingVM.trackingActive.filter { !$0 })
                    .withLatestFrom(self.DataTrackingVM.startDate)
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
            .bind(to: time.rx.text)
            .disposed(by: disposeBag)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func inputBind() {
        self.clueButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                PermissionManager.requestPermission(type: .camera) { [weak self] isAllowed in
                    guard let self else { return }
                    switch isAllowed {
                    case true:
                        let cameraViewModel = CameraViewModel()
                        cameraViewModel.input.accept(.sender(.clueLeave))
                        
                        let cameraView = UINavigationController(rootViewController: CameraViewController(viewModel: cameraViewModel))
                        cameraView.modalPresentationStyle = .fullScreen
                        self.present(cameraView, animated: true)
                        
                    case false:
                        let alert = AlertManager(message: "카메라 권한이 필요합니다.\n 설정에서 변경해주세요.", buttonTitles: ["확인"], buttonActions: [nil])
                        
                        self.present(alert, animated: true)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        self.endButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.DataTrackingVM.stopTracking()
                
                guard let viewModel = self?.DataTrackingVM else { return }
                let endVC = WalkEndModalViewController(viewModel: viewModel)
                let nav = UINavigationController(rootViewController: endVC)
                nav.modalPresentationStyle = .overFullScreen
                self?.present(nav, animated: true)
            })
            .disposed(by: disposeBag)

        self.walkStartButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.startInvestigation()
                self?.viewModel.startTracking.accept(())
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
    }

    private func configureInitialVisibility() {
        // 시작 시 상태 뷰 및 버튼 숨김
        statusView.isHidden = true
        clueButton.isHidden = true
        endButton.isHidden = true
    }

    private func startInvestigation() {
        hasSetInitialCamera = false
        statusView.isHidden = false
        clueButton.isHidden = false
        endButton.isHidden = false
        walkStartButton.isHidden = true
        
        DataTrackingVM.startTracking()
    }
    private func setupUI() {
        // 지도 배경 설정
        mapView.positionMode = .direction
        
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
        [distance, time, steps].forEach {
            $0.textAlignment = .center
            $0.font = .highlight3
            $0.textColor = .textPrimary
        }
        
        distance.text = "0.45"
        time.text = "00:00:00"
        steps.text = "1234"
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
        
        detectiveImageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        detectiveImageStack.spacing = image.count > 1 ? -8 : 0

        image.forEach { name in
            let imageView = UIImageView(image: UIImage(named: name))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 12
            imageView.layer.borderColor = UIColor(named: "textInverse")?.cgColor
            imageView.layer.borderWidth = 1
            imageView.snp.makeConstraints { $0.size.equalTo(24) }
            detectiveImageStack.addArrangedSubview(imageView)
        }
        statusLabel.text = image.count > 1 ? "멍탐정들과 함께 수사 중" : "멍탐정과 함께 수사 중"
        
        // 버튼 설정
        clueButton.setTitle("단서 남기기", for: .normal)
        clueButton.setTitleColor(.white, for: .normal)
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
        
        [distance, time, steps].forEach { valueStack.addArrangedSubview($0) }
        
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
    
    private func bind() {
        viewModel.coordinates
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (coords: [CLLocationCoordinate2D]) in
                guard let self = self else { return }
                guard coords.count >= 2 else { return }

                let nmfCoords = coords.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) as AnyObject }
                let path = NMGLineString(points: nmfCoords)

                let pathOverlay = NMFPath()
                pathOverlay.path = path
                pathOverlay.color = .keycolorPrimary1
                pathOverlay.width = 4
                pathOverlay.mapView = self.mapView

            })
            .disposed(by: disposeBag)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

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
}
