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
    
    @Published var active: Bool?
    
    // The BridgingCoordinator received from the SwiftUI View
    var startScreenViewControllerBridgingCoordinator: StartScreenBridgingCoordinator!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set self to the BridgingCoordinator
        startScreenViewControllerBridgingCoordinator.startScreenViewController = self
    }

    func createSettings(settings: [Settings], modelContext: ModelContext) {
        // Create settings if none exist
        if settings.count < 1 {
            modelContext.insert(Settings())
        }
    }
    
    func setActiveToTrue(active: Bool) { //-> Bool{
        
        self.active = active
        self.active = true
        
    }
}
