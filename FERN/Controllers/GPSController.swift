//
//  GPSController.swift
//  FERN
//
//  Created by Hopp, Dan on 6/13/24.
//

import SwiftUI
// Create a Coordinator
class GpsBridgingCoordinator: ObservableObject {
    var gpsController: GpsController!
}

// The UIViewControllerRepresentable of the ViewController
struct GpsViewControllerRepresentable: UIViewControllerRepresentable {
    var gpsBridgingCoordinator: GpsBridgingCoordinator

    func makeCoordinator() -> GpsCoordinator {
        return GpsCoordinator(self)
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let gpsViewController = GpsController()
        gpsViewController.gpsControllerBridgingCoordinator = gpsBridgingCoordinator
        return gpsViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        //
    }

    class GpsCoordinator: NSObject {
        let parent: GpsViewControllerRepresentable
        init(_ view: GpsViewControllerRepresentable) {
            self.parent = view
        }
    }
}
