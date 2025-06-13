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

// MARK: - CameraViewController
class CameraViewController: UIViewController {
    
    private let viewModel = CameraViewModel()
    private let disposeBag = DisposeBag()
    
    private var viewControllerForPicture: UIViewController
    
    private let captureSession = AVCaptureSession()
    private let captureDevice = AVCaptureDevice.default(for: .video)
    private let photoOutput = AVCapturePhotoOutput()
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let cameraView = UIView()
    private let pinchGesture = UIPinchGestureRecognizer()
    private let shutterButton = UIButton()
    
    // MARK: - Initialize
    init(to destination: CameraDestination) {
        switch destination {
            
        case .clueLeave:
            self.viewControllerForPicture = ClueInputViewController(viewModel: viewModel)
        case .petProfile:
            self.viewControllerForPicture = PetProfileViewController() // todo: 뷰모델 주입
        case .assistantProfile:
            self.viewControllerForPicture = CreateAssistantProfileViewController() // todo: 뷰모델 주입
        case .communityShare:
            self.viewControllerForPicture = CreateLogViewController(viewModel: viewModel)
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.previewLayer?.frame = self.cameraView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !captureSession.isRunning {
            DispatchQueue.global().async {
                self.captureSession.startRunning()
            }
        }
    }
    
}

// MARK: - Method
extension CameraViewController {
    
    private func inputBind() {
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
        
        self.viewModel.output.viewDismissed
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.global().async {
                    self?.captureSession.startRunning()
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
        
        [cameraView, shutterButton]
            .forEach { view.addSubview($0) }
        
        cameraView.layer.insertSublayer(previewLayer, at: 0)
        cameraView.addGestureRecognizer(pinchGesture)
        
        previewLayer.videoGravity = .resizeAspectFill
        
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
        
        DispatchQueue.main.async {
            self.present(self.viewControllerForPicture, animated: true)
        }
    }
}

enum CameraDestination {
    case clueLeave, petProfile, assistantProfile, communityShare
}
