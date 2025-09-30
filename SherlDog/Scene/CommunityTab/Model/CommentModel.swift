//
//  CommentModel.swift
//  SherlDog
//
//  Created by 최규현 on 9/30/25.
//

import FirebaseFirestore

struct CommentModel: Codable {
    let user: HumanProfileModel
    let content: String
    let date: Timestamp
}
