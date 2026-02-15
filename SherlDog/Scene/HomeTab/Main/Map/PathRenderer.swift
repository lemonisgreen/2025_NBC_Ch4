//
//  PathRenderer.swift
//  SherlDog
//
//  Created by JIN LEE on 2/3/26.
//

import NMapsMap
import CoreLocation

final class PathRenderer {
    private weak var mapView: NMFMapView?
    private var pathOverlay: NMFPath?

    init(mapView: NMFMapView) {
        self.mapView = mapView
    }

    func render(coords: [CLLocationCoordinate2D]) {
        guard let mapView else { return }

        guard coords.count >= 2 else {
            clear()
            return
        }

        let overlay = ensureOverlay(on: mapView)

        let nmfPoints: [AnyObject] = coords.map {
            NMGLatLng(lat: $0.latitude, lng: $0.longitude) as AnyObject
        }
        overlay.path = NMGLineString(points: nmfPoints)
    }

    func clear() {
        pathOverlay?.mapView = nil
        pathOverlay = nil
    }

    private func ensureOverlay(on mapView: NMFMapView) -> NMFPath {
        if let pathOverlay { return pathOverlay }

        let overlay = NMFPath()
        overlay.color = .keycolorPrimary1
        overlay.width = 4
        overlay.mapView = mapView
        self.pathOverlay = overlay
        return overlay
    }
}
