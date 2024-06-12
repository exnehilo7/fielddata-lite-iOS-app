//
//  TestJustOneClassForVc.swift
//  FERN
//
//  Created by Hopp, Dan on 6/12/24.
//

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
