//
//  ClueTagMergeStrategy.swift
//  SherlDog
//
//  Created by 해야 on 5/18/26.
//

import ObjectiveC
import NMapsMap

final class ClueTagMergeStrategy: NSObject, NMCTagMergeStrategy {
    func mergeTag(_ cluster: NMCCluster) -> NSObject? {
        var clues: [ClueModel] = []
        
        cluster.children.forEach { child in
            if let tag = child.tag as? ClueLeafTag {
                clues.append(tag.clue)
            } else if let groupTag = child.tag as? ClueClusterTag {
                clues.append(contentsOf: groupTag.clues)
            }
        }
        
        return ClueClusterTag(clues: clues)
    }
}
