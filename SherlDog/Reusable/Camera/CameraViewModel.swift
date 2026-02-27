//
//  CameraViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 6/9/25.
//

import RxSwift
import RxRelay
import UIKit
import CoreLocation

class CameraViewModel {
    
    enum CameraDestination {
        case profile, clueLeave, communityShare
    }
    
    enum Input {
        case sender(CameraDestination)
        case shutterButtonTap
        case captureImage(UIImage)
        case pinchGestureBegan(CGFloat)
        case pinchGestureChanged(CGFloat)
        case dismiss
    }
    
    struct Output {
        let sender = BehaviorRelay<CameraDestination>(value: .profile)
        let getCapture = PublishRelay<Void>()
        let capturedImage = BehaviorRelay<UIImage?>(value: nil)
        let pinchUpdate = PublishRelay<CGFloat>()
        let cameraRestart = PublishRelay<Void>()
    }
    
    private let disposeBag = DisposeBag()
    private let maxZoomScale: CGFloat = 20 // TODO: maximum 줌 값 상의하기
    private let minZoomScale: CGFloat = 1
    private var pinchDefault: CGFloat = 1
    var markerLocation: CLLocationCoordinate2D?
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init() {
        transform()
    }
    
    private func transform() {
        
        input.bind { [weak self] input in
            guard let self else { return }
            
            switch input {
            case .sender(let sender):
                self.output.sender.accept(sender)
                
            case .shutterButtonTap:
                self.output.getCapture.accept(())
                
            case .captureImage(let image):
                self.output.capturedImage.accept(image)
                
            case .pinchGestureBegan(let defaultValue):
                self.pinchDefault = defaultValue
                
            case .pinchGestureChanged(let value):
                self.output.pinchUpdate.accept(self.zoomFactorOperation(value))
                
            case .dismiss:
                self.output.cameraRestart.accept(())
            }
        }
        .disposed(by: disposeBag)
        
    }
    
    private func zoomFactorOperation(_ scale: CGFloat) -> CGFloat {
        var value = self.pinchDefault * scale
        value = max(value, self.minZoomScale)
        value = min(value, self.maxZoomScale)
        
        return value
    }
}
