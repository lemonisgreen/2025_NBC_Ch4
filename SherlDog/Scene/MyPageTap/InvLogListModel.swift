//
//  InvLogListMedel.swift
//  SherlDog
//
//  Created by 최규현 on 6/25/25.
//

import UIKit

struct InvLogListModel: Codable {
    let date: Date
    let caseNumber: Int
    let distance: Double
    let duration: String
    let steps: Int
    let distanceImage: String
}

extension InvLogListModel {
    static let sample = [
        InvLogListModel(date: Date(),
                        caseNumber: 1,
                        distance: 1.23,
                        duration: "1시간 12분",
                        steps: 11234,
                        distanceImage: ""),
        InvLogListModel(date: Date(),
                        caseNumber: 1,
                        distance: 1.23,
                        duration: "1시간 12분",
                        steps: 11234,
                        distanceImage: ""),
        InvLogListModel(date: Date(),
                        caseNumber: 1,
                        distance: 1.23,
                        duration: "1시간 12분",
                        steps: 11234,
                        distanceImage: ""),
        InvLogListModel(date: Date(),
                        caseNumber: 1,
                        distance: 1.23,
                        duration: "1시간 12분",
                        steps: 11234,
                        distanceImage: ""),
        InvLogListModel(date: Date(),
                        caseNumber: 1,
                        distance: 1.23,
                        duration: "1시간 12분",
                        steps: 11234,
                        distanceImage: ""),
        InvLogListModel(date: Date(),
                        caseNumber: 1,
                        distance: 1.23,
                        duration: "1시간 12분",
                        steps: 11234,
                        distanceImage: "")
    ]
}
