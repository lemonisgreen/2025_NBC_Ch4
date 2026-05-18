//
//  ClueLeafMarkerUpdater.swift
//  SherlDog
//
//  Created by 최규현 on 5/13/26.
//

import NMapsMap

final class ClueLeafMarkerUpdater: NMCDefaultLeafMarkerUpdater {
    var onTap: ((ClueModel) -> ())?
    
    override func updateLeafMarker(_ info: NMCLeafMarkerInfo, _ marker: NMFMarker) {
        super.updateLeafMarker(info, marker)
        
        guard let tag = info.tag as? ClueLeafTag else { return }
        let clue = tag.clue
        let id = FirestoreManager.shared.userId
        
        marker.captionText = ""
        marker.position = NMGLatLng(lat: clue.latitude, lng: clue.longitude)
        marker.userInfo = ["clue": clue]
        marker.iconImage = clue.userID == id
        ? .init(image: .communityGreen) // TODO: **반드시 변경할 것!!!!**
        : .init(image: .clueMark)
        marker.width = 60
        marker.height = 60
        
        marker.touchHandler = { [weak self] _ in
            guard let tag = info.tag as? ClueLeafTag else { return true }
            
            self?.onTap?(tag.clue)
            return true
        }
    }
}
