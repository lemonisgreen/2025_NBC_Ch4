//
//  ClueDetailViewModel.swift
//  SherlDog
//
//  Created by 김재우 on 6/19/25.
//

import Foundation
import RxSwift
import RxCocoa

final class ClueDetailViewModel {
    
    // MARK: - Outputs
    let savedClue = BehaviorRelay<ClueModel?>(value: nil)
    let isLoading = BehaviorRelay<Bool>(value: false)
    let errorMessage = PublishRelay<String>()
    
    init(clue: ClueModel) {
        savedClue.accept(clue)
    }
}
