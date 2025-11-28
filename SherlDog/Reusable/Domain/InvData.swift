//
//  InvData.swift
//  SherlDog
//
//  Created by Jin Lee on 11/12/25.
//

import Foundation

/// 산책 종료 후 공유 및 기록 화면 간 데이터를 전달하기 위한 DTO
///
struct InvData {
    /// 걸음 수 (예: 5421)
    let steps: Int
    
    /// 총 이동 거리 (미터 단위)
    let distanceMeters: Double
    
    /// 총 소요 시간 (예: "01:12:23")
    let durationText: String
    
    /// 산책 종료 시각
    let endDate: Date?
    
    /// 산책 중 남긴 단서 수 
    let clueCount: Int?
    
    init(
        steps: Int,
        distanceMeters: Double,
        durationText: String,
        endDate: Date?,
        clueCount: Int? = nil
    ) {
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.durationText = durationText
        self.endDate = endDate
        self.clueCount = clueCount
    }
}
