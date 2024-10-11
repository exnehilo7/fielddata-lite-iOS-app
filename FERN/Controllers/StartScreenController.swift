//
//  StartScreenController.swift
//  FERN
//
//  Created by Hopp, Dan on 6/13/24.
//

//import SwiftUI
//
//// Create a Coordinator
//class StartScreenBridgingCoordinator: ObservableObject {
//    var startScreenViewController : StartScreenViewController!
//}
//
//// The UIViewControllerRepresentable of the vcStartScreenView class
//struct StartScreenViewControllerRepresentable: UIViewControllerRepresentable {
//    var startScreenBridgingCoordinator: StartScreenBridgingCoordinator
//
//    func makeCoordinator() -> StartScreenCoordinator {
//        return StartScreenCoordinator(self)
//    }
//
//    func makeUIViewController(context: Context) -> some UIViewController {
//        let startScreenViewController = StartScreenViewController()
//        startScreenViewController.startScreenViewControllerBridgingCoordinator = startScreenBridgingCoordinator
//        return startScreenViewController
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
//        //
//    }
//
//    class StartScreenCoordinator: NSObject {
//        let parent: StartScreenViewControllerRepresentable
//        init(_ view: StartScreenViewControllerRepresentable) {
//            self.parent = view
//        }
//    }
//}
