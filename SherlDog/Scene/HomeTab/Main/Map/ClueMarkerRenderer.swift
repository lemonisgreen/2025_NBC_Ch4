//
//  ClueMarkerRenderer.swift
//  SherlDog
//
//  Created by JIN LEE on 2/3/26.
//

import NMapsMap
import FirebaseFirestore

final class ClueMarkerRenderer {
    
    private weak var mapView: NMFMapView?
    private var clusterer: NMCClusterer<ClueClusterKey>?
    
    var onTapMarker: ((ClueModel) -> Void)?
    var onTapCluster: (([ClueModel]) -> ())?
    
    init(mapView: NMFMapView) {
        self.mapView = mapView
        
        self.setupClusterer()
    }
    
    // MARK: - Clusterer
    func setupClusterer() {
        let builder = NMCComplexBuilder<ClueClusterKey>()
        
        builder.tagMergeStrategy = ClueTagMergeStrategy()
        
        // 개별 마커 updater
        let leafUpdater = ClueLeafMarkerUpdater()
        leafUpdater.onTap = { [weak self] clue in
            self?.onTapMarker?(clue)
        }
        
        // 클러스터 마커 updater
        let clusterUpdater = ClueClusterMarkerUpdater()
        clusterUpdater.onTap = { [weak self] clues in
            self?.onTapCluster?(clues)
        }
        
        builder.leafMarkerUpdater = leafUpdater
        builder.clusterMarkerUpdater = clusterUpdater
        
        let clusterer = builder.build()
        clusterer.mapView = mapView
        
        self.clusterer = clusterer
    }
    
    func updateClusters(items: [ClueModel]) {
        guard let clusterer else { return }
        
        let items = items.map {
            guard let id = $0.documentId else { return ClueMapItem(id: UUID().uuidString, model: $0) }
            
            return ClueMapItem(
                id: id,
                model: $0
            )
        }
        
        clusterer.clear()
        
        let keyTagMap: [AnyHashable: NSObject] = Dictionary(
            uniqueKeysWithValues: items.map { item in
                let key = ClueClusterKey(
                    identifier: item.id,
                    position: NMGLatLng(
                        lat: item.model.latitude,
                        lng: item.model.longitude
                    )
                )
                
                let tag = ClueLeafTag(clue: item.model)
                
                return (AnyHashable(key), tag)
            }
        )
        
        clusterer.addAll(keyTagMap)
    }
}

