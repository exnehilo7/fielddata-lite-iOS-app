//
//  MapController.swift
//  FERN
//
//  Created by Hopp, Dan on 6/17/24.
//

import SwiftUI

// Create a Coordinator
class MapBridgingCoordinator: ObservableObject {
    var mapController: MapController!
}

// The UIViewControllerRepresentable of the ViewController
struct MapViewControllerRepresentable: UIViewControllerRepresentable {
    var mapBridgingCoordinator: MapBridgingCoordinator

    func makeCoordinator() -> MapCoordinator {
        return MapCoordinator(self)
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let mapViewController = MapController()
        mapViewController.mapControllerBridgingCoordinator = mapBridgingCoordinator
        return mapViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        //
    }

    class MapCoordinator: NSObject {
        let parent: MapViewControllerRepresentable
        init(_ view: MapViewControllerRepresentable) {
            self.parent = view
        }
    }
}
