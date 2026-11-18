//
//  WalkResultToList.swift
//  SherlDog
//
//  Created by 최규현 on 6/26/25.
//

import UIKit
import RxSwift

struct WalkResultToList {
    let date: String
    let distance: String
    let duration: String
    let steps: String
    var petProfile: [PetProfile]
    let caseNumber: String
}

extension WalkResultToList {
    init(from result: WalkResult, caseNumber: Int, profile: [PetProfile]) {
        let formatter = DateFormatter()
        
        // MARK: result.date transform -
        formatter.dateFormat = "yyyy-MM-dd"
        
        let sampleDate = formatter.date(from: result.date) ?? Date()
        let date = DateFormatter.mddDotyyyy.string(from: sampleDate)
        
        // MARK: result.duration transform -
        formatter.dateFormat = "HH:mm:ss"
        
        let sampleDuration = formatter.date(from: result.duration) ?? Date()
        let duration = DateFormatter.hm.string(from: sampleDuration)
        
        // MARK: tranform -
        self.date = date
        self.distance = String(format: "%.1fkm", result.distance / 1000.0)
        self.duration = duration
        self.steps = "\(result.steps)보"
        self.caseNumber = String(format: "%03d", caseNumber)
        self.petProfile = profile
    }
}
