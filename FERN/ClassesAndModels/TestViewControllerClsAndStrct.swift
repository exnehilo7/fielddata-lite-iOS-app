//
//  TestViewControllerClsAndStrct.swift
//  FERN
//
//  Created by Hopp, Dan on 6/12/24.
//

import Foundation
import SwiftUI

// Create a Coordinator
class BridgingCoordinator: ObservableObject {
    var vc: ViewController!
}

// The UIViewControllerRepresentable of the ViewController
struct UIViewControllerRepresentation: UIViewControllerRepresentable {
    var bridgingCoordinator: BridgingCoordinator

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = ViewController()
        vc.bridgingCoordinator = bridgingCoordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        //
    }

    class Coordinator: NSObject {
        let parent: UIViewControllerRepresentation
        init(_ view: UIViewControllerRepresentation) {
            self.parent = view
        }
    }
}

//// ViewController which contains functions that need to be called from SwiftUI
//class ViewController: UIViewController {
//    // The BridgingCoordinator received from the SwiftUI View
//    var bridgingCoordinator: BridgingCoordinator!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Set self to the BridgingCoordinator
//        bridgingCoordinator.vc = self
//    }
//
//    func doSomething() {
//        print("Received function call from SwiftUI View")
//    }
//}
