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
    
    private let captureSession = AVCaptureSession()
    private let captureDevice = AVCaptureDevice.default(for: .video)
    private let photoOutput = AVCapturePhotoOutput()
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let cameraView = UIView()
    private let pinchGesture = UIPinchGestureRecognizer()
    private let shutterButton = UIButton()
    
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
            /*
             
            사진을 찍으면 넘어갈 뷰 컨트롤러를 지정
            해당 뷰 컨트롤러는 init에서 CameraViewModel타입을 전달받을 수 있도록 해야하며
            전달받은 뷰모델의 output.capturedImage를 구독해 이미지를 전달받을 수 있음
             
            let imageVC = ViewController(viewModel: self.viewModel)
            self.navigationController?.pushViewController(imageVC, animated: true)
             
             */
        }
    }
}
