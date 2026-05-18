//
//  ClueClusterTag.swift
//  SherlDog
//
//  Created by 해야 on 5/18/26.
//

import ObjectiveC

final class ClueClusterTag: NSObject {
    let clues: [ClueModel]
    
    init(clues: [ClueModel]) {
        self.clues = clues
    }
}
