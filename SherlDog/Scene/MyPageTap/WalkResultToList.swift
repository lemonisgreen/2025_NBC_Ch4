//
//  WalkResultToList.swift
//  SherlDog
//
//  Created by 최규현 on 6/26/25.
//

import UIKit

struct WalkResultToList {
    let date: String
    let distance: String
    let duration: String
    let steps: String
    let walkingPathImage: String
}

extension WalkResultToList {
    init(from result: WalkResult) {
        let formatter = DateFormatter()
        
        // MARK: result.date transform -
        formatter.dateFormat = "yyyy-MM-dd"
        let date: String
        
        if let sampleDate = formatter.date(from: result.date) {
            formatter.dateFormat = "M월 dd, yyyy"
            date = formatter.string(from: sampleDate)
        } else {
            date = ""
        }
        
        // MARK: result.duration transform -
        formatter.dateFormat = "HH:mm:ss"
        let duration: String
        
        if let sampleDuration = formatter.date(from: result.duration) {
            formatter.dateFormat = "H시간 m분"
            duration = formatter.string(from: sampleDuration)
        } else {
            duration = ""
        }
        
        // MARK: tranform -
        self.date = date
        self.distance = "\(result.distance / 1000)km"
        self.duration = duration
        self.steps = "\(result.steps)보"
        self.walkingPathImage = result.walkingPathImage
    }
}
