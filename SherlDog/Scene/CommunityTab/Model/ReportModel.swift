//
//  ReportModel.swift
//  SherlDog
//
//  Created by Jin Lee on 11/22/25.
//

import Foundation
import FirebaseFirestore

struct ReportModel: Codable {
    let reporterId: String          // 신고한 사람
    let targetUserId: String?       // 신고 당한 유저 (게시글/프로필 등)
    let targetPostId: String?       // 신고한 게시글 id (있다면)
    let targetCollection: String    // 어떤 컬렉션의 문서인지 (탐정메이트, 수사일지 등)
    let reason: String              // 선택한 신고 사유
    let detail: String              // 사용자가 쓴 구체 사유
    let createdAt: Timestamp        // 신고 시간
}
