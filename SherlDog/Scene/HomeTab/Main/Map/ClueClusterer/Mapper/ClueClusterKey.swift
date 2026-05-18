//
//  ClueClusterKey.swift
//  SherlDog
//
//  Created by 최규현 on 5/11/26.
//

import NMapsMap

final class ClueClusterKey: NSObject, NMCClusteringKey {
    let identifier: String
    let position: NMGLatLng
    
    override var hash: Int {
        return identifier.hashValue
    }
    
    init(identifier: String, position: NMGLatLng) {
        self.identifier = identifier
        self.position = position
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ClueClusterKey else { return false }
        return identifier == other.identifier
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return ClueClusterKey(identifier: identifier, position: position)
    }
    
    
}
