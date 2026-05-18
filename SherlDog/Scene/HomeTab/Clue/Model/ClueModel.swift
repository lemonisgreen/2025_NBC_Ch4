//
//  ClueModel.swift
//  SherlDog
//
//  Created by 김재우 on 6/19/25.
//

import Foundation
import FirebaseFirestore

struct ClueModel: Codable {
    @DocumentID var documentId: String?
    
    let userID: String
    let latitude: Double
    let longitude: Double
    let content: String
    let image: String
    let date: Timestamp
    
    enum CodingKeys: String, CodingKey {
        case userID
        case latitude
        case longitude
        case content
        case image
        case date
    }
}
