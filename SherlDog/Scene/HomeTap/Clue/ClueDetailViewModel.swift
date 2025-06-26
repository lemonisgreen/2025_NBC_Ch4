//
//  ClueDetailViewModel.swift
//  SherlDog
//
//  Created by 김재우 on 6/19/25.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

final class ClueDetailViewModel {
    
    // MARK: - Outputs
    let savedClue = BehaviorRelay<ClueModel?>(value: nil)
    let isLoading = BehaviorRelay<Bool>(value: false)
    let errorMessage = PublishRelay<String>()
    
    init(clue: ClueModel) {
        savedClue.accept(clue)
    }
    
    // 새로운 초기화 메서드 추가
    init(coordinate: CLLocationCoordinate2D) {
        // 좌표만으로 새 단서를 만드는 경우
        savedClue.accept(nil)
    }
}
