//
//  CameraViewController.swift
//  SherlDog
//
//  Created by 최규현 on 6/9/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import AVFoundation
import CoreLocation

// MARK: - CameraViewController
class CameraViewController: UIViewController {
    
    private let viewModel: CameraViewModel
    private let invData: InvData?
    private let disposeBag = DisposeBag()
    
    private var viewControllerForPicture: UIViewController?
    
    private let captureSession = AVCaptureSession()
    private let captureDevice = AVCaptureDevice.default(for: .video)
    private let photoOutput = AVCapturePhotoOutput()
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let cameraView = UIView()
    private let pinchGesture = UIPinchGestureRecognizer()
    private let shutterButton = UIButton()
    private let cancelButton = UIButton()
    private let guideLabel = UILabel()
    private let gradientLayer = CAGradientLayer()
    
    // MARK: - Initialize
    init(viewModel: CameraViewModel, invData: InvData? = nil) {
        self.viewModel = viewModel
        self.invData = invData

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        gradientLayer.frame = cameraView.bounds
    }
}

// MARK: - Lifecycle
extension CameraViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        setupUI()
        configureUI()
        bind()
        inputBind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.previewLayer?.frame = self.cameraView.bounds
    }
}

// MARK: - Method
extension CameraViewController {
    
    private func inputBind() {
        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        shutterButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.input.accept(.shutterButtonTap)
            })
            .disposed(by: disposeBag)
        
        pinchGesture.rx.event
            .subscribe(onNext: { [weak self] event in
                guard let self,
                      let captureDevice = self.captureDevice else { return }
                
                switch event.state {
                case .began:
                    self.viewModel.input.accept(.pinchGestureBegan(captureDevice.videoZoomFactor))
                case .changed:
                    self.viewModel.input.accept(.pinchGestureChanged(event.scale))
                default:
                    return
                }
            })
        .disposed(by: disposeBag)
    }
    
    private func bind() {
        
        self.viewModel.output.sender
            .subscribe(onNext: { [weak self] sender in
                guard let self else { return }
                
                switch sender {
                case .clueLeave:
                    let location = self.viewModel.markerLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
                    self.viewControllerForPicture = UINavigationController(
                        rootViewController: ClueInputViewController(
                            viewModel: viewModel,
                            location: location
                        )
                    )
                    self.guideLabel.isHidden = false
                    
                case .communityShare:
                    
                    self.viewControllerForPicture = UINavigationController(
                                          rootViewController: CreateLogViewController(
                                              viewModel: self.viewModel,
                                              invData: self.invData
                                          )
                                      )
                    
                case .profile: return
                }
            })
            .disposed(by: disposeBag)
        
        self.viewModel.output.getCapture
            .subscribe { [weak self] _ in
                guard let self else { return }
                self.photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            }
            .disposed(by: disposeBag)
        
        self.viewModel.output.pinchUpdate
            .subscribe(onNext: { [weak self] scale in
                guard let self, let captureDevice = self.captureDevice else { return }
                try? captureDevice.lockForConfiguration()
                captureDevice.videoZoomFactor = scale
                captureDevice.unlockForConfiguration()
            })
            .disposed(by: disposeBag)
        
        self.viewModel.output.cameraRestart
            .bind(onNext: { [weak self] in
                guard let self else { return }
                
                if !self.captureSession.isRunning {
                    DispatchQueue.global().async {
                        self.captureSession.startRunning()
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupCamera() {
        guard let captureDevice else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            captureSession.beginConfiguration()
            
            if captureSession.canSetSessionPreset(.photo),
               captureSession.canAddInput(input),
               captureSession.canAddOutput(photoOutput) {
                
                captureSession.sessionPreset = .photo
                captureSession.addInput(input)
                captureSession.addOutput(photoOutput)
            }
            
            self.captureSession.commitConfiguration()
            
        } catch {
            
        }
        
        self.previewLayer = .init(session: captureSession)
        
        DispatchQueue.global().async {
            self.captureSession.startRunning()
        }
    }
    
    private func setupUI() {
        guard let previewLayer else { return }
        
        [cameraView, shutterButton, guideLabel, cancelButton]
            .forEach { view.addSubview($0) }
        
        cameraView.layer.insertSublayer(previewLayer, at: 0)
        cameraView.addGestureRecognizer(pinchGesture)
        
        cameraView.layer.addSublayer(gradientLayer)
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(1).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.startPoint = .init(x: 0.5, y: 0.0)
        gradientLayer.endPoint = .init(x: 0.5, y: 0.3)
        
        previewLayer.videoGravity = .resizeAspectFill
        
        cancelButton.setImage(.modalExit.withRenderingMode(.alwaysTemplate), for: .normal)
        cancelButton.imageView?.tintColor = .textInverse
        
        guideLabel.text = "멍탐정과의 추억을 단서로 남겨보세요!"
        guideLabel.textColor = .textInverse
        guideLabel.font = .highlight5
        guideLabel.backgroundColor = .gray600.withAlphaComponent(0.3)
        guideLabel.textAlignment = .center
        guideLabel.layer.cornerRadius = 6
        guideLabel.clipsToBounds = true
        guideLabel.isHidden = true
        
        shutterButton.setImage(UIImage(named: "cameraShutter"), for: .normal)
    }
    
    private func configureUI() {
        cameraView.snp.makeConstraints {
            $0.center.width.height.equalToSuperview()
        }
        
        shutterButton.snp.makeConstraints {
            $0.width.height.equalTo(72)
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(36)
        }
        
        cancelButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.trailing.equalToSuperview().inset(18)
        }
        
        guideLabel.snp.makeConstraints {
            $0.top.equalTo(cancelButton.snp.bottom).offset(18)
            $0.leading.trailing.equalToSuperview().inset(33.5)
            $0.height.equalTo(56)
        }
    }
    
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        self.viewModel.input.accept(.captureImage(image))
        
        DispatchQueue.global().async {
            self.captureSession.stopRunning()
        }
        
        switch self.viewModel.output.sender.value {
        case .profile:
            DispatchQueue.main.async {
                self.presentingViewController?.presentingViewController?.dismiss(animated: true)
            }
            
        case .clueLeave, .communityShare:
            guard let viewControllerForPicture else { return }
            viewControllerForPicture.presentationController?.delegate = self
            viewControllerForPicture.sheetPresentationController?.prefersGrabberVisible = true
            viewControllerForPicture.isModalInPresentation = true
            
            DispatchQueue.main.async {
                self.present(viewControllerForPicture, animated: true)
            }
        }
        
    }
}

extension CameraViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        
        if !self.captureSession.isRunning {
            DispatchQueue.global().async {
                self.captureSession.startRunning()
            }
        }
    }
}
