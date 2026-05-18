//
//  ClueClusterMarkerUpdater.swift
//  SherlDog
//
//  Created by 최규현 on 5/13/26.
//

import NMapsMap

final class ClueClusterMarkerUpdater: NMCDefaultClusterMarkerUpdater {
    var onTap: (([ClueModel]) -> ())?
    
    override func updateClusterMarker(_ info: NMCClusterMarkerInfo, _ marker: NMFMarker) {
        super.updateClusterMarker(info, marker)
        
        marker.iconImage = NMF_MARKER_IMAGE_CLUSTER_MEDIUM_DENSITY
        marker.width = 60
        marker.height = 60
        marker.captionText = "\(info.size)"
        
        marker.touchHandler = { [weak self] _ in
            guard let groupTag = info.tag as? ClueClusterTag else { return false }
            
            self?.onTap?(groupTag.clues)
            return true
        }
    }
}
