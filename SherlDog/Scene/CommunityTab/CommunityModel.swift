//
//  CommunityModelTest.swift
//  SherlDog
//
//  Created by 최규현 on 6/12/25.
//

import UIKit

// MARK: - CommunityModel
struct CommunityModel {
    let profileImage: UIImage?
    let name: String
    let info: String
    let postDate: String
    let contentImage: UIImage?
    let content: String
    var isExpanded: Bool = false
}
