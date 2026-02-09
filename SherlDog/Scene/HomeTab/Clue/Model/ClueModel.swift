//
//  ClueModel.swift
//  SherlDog
//
//  Created by 김재우 on 6/19/25.
//

import Foundation
import FirebaseFirestore

struct ClueModel: Codable {
    let userID: String
    let latitude: Double
    let longitude: Double
    let content: String
    let image: String
    let date: Timestamp
}
