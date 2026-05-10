//
//  ClueMarkerRenderer.swift
//  SherlDog
//
//  Created by JIN LEE on 2/3/26.
//

import NMapsMap

final class ClueMarkerRenderer {

    private weak var mapView: NMFMapView?
    private var markers: [NMFMarker] = []

    var onTapMarker: ((ClueModel) -> Void)?

    init(mapView: NMFMapView) {
        self.mapView = mapView
    }

    func render(clues: [ClueModel]) {
        guard let mapView else { return }
        let id = FirestoreManager.shared.userId

        clear()

        for clue in clues {
            let marker = NMFMarker()
            marker.position = NMGLatLng(lat: clue.latitude, lng: clue.longitude)
            marker.userInfo = ["clue": clue]
            marker.iconImage = clue.userID == id
            ? NMFOverlayImage(name: "communityGreen") // TODO: **반드시 변경할 것!!!!**
            : NMFOverlayImage(name: "clueMark")
            marker.width = 60
            marker.height = 60
            marker.mapView = mapView
            
            marker.touchHandler = { [weak self] overlay in
                guard
                    let marker = overlay as? NMFMarker,
                    let clue = marker.userInfo["clue"] as? ClueModel
                else { return false }

                self?.onTapMarker?(clue)
                return true
            }

            markers.append(marker)
        }
    }

    func clear() {
        markers.forEach { $0.mapView = nil }
        markers.removeAll()
    }

    func addTemporaryMarker(
        latitude: Double,
        longitude: Double,
        onTap: @escaping () -> Void
    ) {
        guard let mapView else { return }

        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: latitude, lng: longitude)
        marker.iconImage = NMFOverlayImage(name: "communityGreen")
        marker.width = 60
        marker.height = 60
        marker.mapView = mapView

        marker.touchHandler = { _ in
            onTap()
            return true
        }

        markers.append(marker)
    }
}
