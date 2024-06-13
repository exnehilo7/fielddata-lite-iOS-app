//
//  StartScreenModel.swift
//  FERN
//
//  Created by Hopp, Dan on 6/13/24.
//

import SwiftUI
import SwiftData

// ViewController which contains functions that need to be called from SwiftUI
class StartScreenViewController: UIViewController {
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    // The BridgingCoordinator received from the SwiftUI View
    var startScreenViewControllerBridgingCoordinator: StartScreenBridgingCoordinator!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set self to the BridgingCoordinator
        startScreenViewControllerBridgingCoordinator.startScreenViewController = self
    }

    func createSettings() {
        // Create settings if none exist
        if settings.count < 1 {
            modelContext.insert(Settings())
        }
    }
}
