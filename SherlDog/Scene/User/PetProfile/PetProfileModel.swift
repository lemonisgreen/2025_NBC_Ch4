//
//  PetProfileModel.swift
//  SherlDog
//
//  Created by 최영락 on 6/16/25.
//

import Foundation
import FirebaseFirestore

struct PetProfile: Codable {
    let petProfileId: String
    let userId: String
    let name: String
    let age: String
    let size: String
    let image: String
    let gender: String
    let neutered: Bool
    let breed: String
    let introduce: String
}
