//
//  LoadingIndicator.swift
//  SherlDog
//
//  Created by 최규현 on 7/30/25.
//

import UIKit
import Lottie

// MARK: - LoadingIndicator
class CustomLoadingIndicator: UIView {
    
    private let lottieAnimation = LottieAnimationView(name: "Loading")
    
    /// isHidden 옵션을 해제하면 작동 시작,
    /// 옵션을 true로 두면 작동 종료
    override var isHidden: Bool {
        didSet {
            self.loading()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        setup()
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(lottieAnimation)
        
        backgroundColor = .keycolorTertiaryBG
        
        lottieAnimation.contentMode = .scaleAspectFit
        lottieAnimation.loopMode = .loop
        lottieAnimation.animationSpeed = 1.0
        
        lottieAnimation.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func loading() {
        isHidden ? lottieAnimation.stop() : lottieAnimation.play()
    }
}
