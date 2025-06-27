//
//  DataTrackingModel.swift
//  SherlDog
//
//  Created by JIN LEE on 6/23/25.
//

import Foundation
import FirebaseFirestore

struct WalkResult: Codable {
    let userId: String
    let petProfileId: [String]
    let date: String
    let distance: Double
    let duration: String
    let steps: Int
    let walkingPathImage: String
    let createdAt: Timestamp
}
