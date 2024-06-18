//
//  CameraController.swift
//  FERN
//
//  Created by Hopp, Dan on 6/18/24.
//

import SwiftUI

// Create a Coordinator
class CameraBridgingCoordinator: ObservableObject {
    var cameraController: CameraController!
}

// The UIViewControllerRepresentable of the ViewController
struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    var cameraBridgingCoordinator: CameraBridgingCoordinator

    func makeCoordinator() -> CameraCoordinator {
        return CameraCoordinator(self)
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let cameraViewController = CameraController()
        cameraViewController.cameraControllerBridgingCoordinator = cameraBridgingCoordinator
        return cameraViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        //
    }

    class CameraCoordinator: NSObject {
        let parent: CameraViewControllerRepresentable
        init(_ view: CameraViewControllerRepresentable) {
            self.parent = view
        }
    }
}

