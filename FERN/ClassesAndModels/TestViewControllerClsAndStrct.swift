//
//  TestViewControllerClsAndStrct.swift
//  FERN
//
//  Created by Hopp, Dan on 6/12/24.
//  A template for MVC. Controller part.
//  From https://stackoverflow.com/questions/62504435/how-to-call-a-uikit-viewcontroller-method-from-swiftui-view

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
