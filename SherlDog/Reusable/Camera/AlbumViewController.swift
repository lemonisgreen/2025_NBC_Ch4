//
//  AlbumViewController.swift
//  SherlDog
//
//  Created by 최규현 on 6/17/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import CoreLocation

// MARK: - AlbumViewController
class AlbumViewController: UIViewController {
    
    private let viewModel: CameraViewModel
    private let invData: InvData?
    private let disposeBag = DisposeBag()
    
    private var viewControllerForPicture: UIViewController?
    private let pickerController = UIImagePickerController()
    
    // MARK: - Lifecycle
    init(viewModel: CameraViewModel, invData: InvData? = nil) {
        self.viewModel = viewModel
        self.invData = invData

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bind()
        setupAlbum()
    }
    
    // MARK: - Method
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
    }
    
    private func setupAlbum() {
        self.pickerController.delegate = self
        self.pickerController.sourceType = .photoLibrary
        self.pickerController.presentationController?.delegate = self
        
        self.present(pickerController, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AlbumViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        self.viewModel.input.accept(.captureImage(image))
        picker.dismiss(animated: true)
        
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

// MARK: - UIAdaptivePresentationControllerDelegate
extension AlbumViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.dismiss(animated: false)
    }
}
