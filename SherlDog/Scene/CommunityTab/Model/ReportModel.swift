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
    let targetUserId: String?       // 신고 당한 유저
    let targetPostId: String?       // 신고한 게시글 id
    let targetCollection: String    // 탐정메이트 or 수사일지
    let reason: String              // 선택한 신고 사유
    let detail: String              // 신고자가 쓴 구체 사유
    let createdAt: Timestamp        // 신고 시간
}
