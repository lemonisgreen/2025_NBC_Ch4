//
//  CommentModel.swift
//  SherlDog
//
//  Created by 최규현 on 9/30/25.
//

import FirebaseFirestore

struct CommentModel: Codable {
    let userId: String
    let user: HumanProfileModel
    let content: String
    var documentId: String = ""
    let date: Timestamp
    let isSecret: Bool
}
