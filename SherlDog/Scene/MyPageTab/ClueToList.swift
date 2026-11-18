//
//  ClueToList.swift
//  SherlDog
//
//  Created by 최규현 on 11/17/26.
//

import Foundation

struct ClueToList {
    let date: String
    let clue: ClueModel
    let petProfile: [PetProfile]
    let caseNumber: String

    init(from clue: ClueModel, caseNumber: Int, profile: [PetProfile]) {
        self.date = DateFormatter.mddDotyyyy.string(from: clue.date.dateValue())
        self.clue = clue
        self.petProfile = profile
        self.caseNumber = String(format: "%03d", caseNumber)
    }
}
