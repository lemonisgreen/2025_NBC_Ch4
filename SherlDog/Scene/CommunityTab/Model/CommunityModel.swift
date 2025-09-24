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
    var profileImage: String = ""
    var name: String = ""
    var petProfile: [PetProfile]
    let postDate: Timestamp
    let contentImage: [String]
    let content: String
    var likeCount: Int = 0
    var commentCount: Int = 0
    let documentId: String
    var isExpanded: Bool = false
}
