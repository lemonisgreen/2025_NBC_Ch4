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

// test
extension CommunityModel {
    static let sample: [CommunityModel] = [
        CommunityModel(profileImage: UIImage(named: "bigLogo"),
                       name: "강아지명",
                       info: "3세 여아 / 말티즈",
                       postDate: "1시간",
                       contentImage: .kakao,
                       content: "testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest"),
        CommunityModel(profileImage: UIImage(named: "apple"),
                       name: "강아지명",
                       info: "3세 여아 / 말티즈",
                       postDate: "1시간",
                       contentImage: .naver,
                       content: "testtesttesttestteststtesttesttest"),
        CommunityModel(profileImage: UIImage(named: "avatar"),
                       name: "강아지명",
                       info: "3세 여아 / 말티즈",
                       postDate: "1시간",
                       contentImage: .logo,
                       content: "testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest")
    ]
}
