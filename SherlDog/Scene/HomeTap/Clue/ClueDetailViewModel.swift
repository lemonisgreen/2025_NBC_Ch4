//
//  ClueDetailViewModel.swift
//  SherlDog
//
//  Created by 김재우 on 6/19/25.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa

final class ClueDetailViewModel {

    // MARK: - Inputs
    private let coordinate: CLLocationCoordinate2D

    // MARK: - Stored data
    let savedClue = PublishRelay<ClueModel>()

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }

    func saveClue(userID: String, content: String, imagePath: String) {
        let clue = ClueModel(
            userID: userID,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            content: content,
            image: imagePath
        )
        savedClue.accept(clue)
    }
}
