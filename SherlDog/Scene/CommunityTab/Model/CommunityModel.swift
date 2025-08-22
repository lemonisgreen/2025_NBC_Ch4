//
//  CommunityModelTest.swift
//  SherlDog
//
//  Created by 최규현 on 6/12/25.
//

import UIKit
import FirebaseFirestore

// MARK: - CommunityModel
struct CommunityModel: Codable {
    let userId: String
    let profileImage: String
    let name: String
    let info: [PetProfile]
    let postDate: Timestamp
    let contentImage: [String]
    let content: String
    var isExpanded: Bool = false
}
