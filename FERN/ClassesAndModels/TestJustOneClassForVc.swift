//
//  TestJustOneClassForVc.swift
//  FERN
//
//  Created by Hopp, Dan on 6/12/24.
//  A template for MVC. Model part.
//  From https://stackoverflow.com/questions/62504435/how-to-call-a-uikit-viewcontroller-method-from-swiftui-view

import Foundation
import SwiftUI


// ViewController which contains functions that need to be called from SwiftUI
class ViewController: UIViewController {
    // The BridgingCoordinator received from the SwiftUI View
    var bridgingCoordinator: BridgingCoordinator!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set self to the BridgingCoordinator
        bridgingCoordinator.vc = self
    }

    func doSomething() {
        print("Received function call from SwiftUI View")
    }
}
