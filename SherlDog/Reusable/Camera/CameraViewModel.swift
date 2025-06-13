//
//  CameraViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 6/9/25.
//

import RxSwift
import RxRelay
import UIKit

class CameraViewModel {
    
    enum Input {
        case shutterButtonTap
        case captureImage(UIImage)
        case pinchGestureBegan(CGFloat)
        case pinchGestureChanged(CGFloat)
        case viewDismissed
    }
    
    struct Output {
        let getCapture = PublishRelay<Void>()
        let capturedImage = BehaviorRelay<UIImage?>(value: nil)
        let pinchUpdate = PublishRelay<CGFloat>()
        let viewDismissed = PublishRelay<Void>()
    }
    
    private let disposeBag = DisposeBag()
    private let maxZoomScale: CGFloat = 100
    private let minZoomScale: CGFloat = 1
    private var pinchDefault: CGFloat = 1
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init() {
        transform()
    }
    
    private func transform() {
        
        input.bind { input in
            switch input {
            case .shutterButtonTap:
                self.output.getCapture.accept(())
                
            case .captureImage(let image):
                self.output.capturedImage.accept(image)
                
            case .pinchGestureBegan(let defaultValue):
                self.pinchDefault = defaultValue
                
            case .pinchGestureChanged(let value):
                self.output.pinchUpdate.accept(self.zoomFactorOperation(value))
            case .viewDismissed:
                self.output.viewDismissed.accept(())
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
