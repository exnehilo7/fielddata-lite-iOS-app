//
//  GPSModel.swift
//  FERN
//
//  Created by Hopp, Dan on 6/13/24.
//

import SwiftUI
import SwiftData

// ViewController which contains functions that need to be called from SwiftUI
class GpsController: UIViewController {
    
    @Published var nmea: NMEA?
    @Published var clLocationHelper: LocationHelper?
    
    // The BridgingCoordinator received from the SwiftUI View
    var gpsControllerBridgingCoordinator: GpsBridgingCoordinator!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set self to the BridgingCoordinator
        gpsControllerBridgingCoordinator.gpsController = self
    }

    func startGPSFeed(settings: [Settings]) {
        if settings[0].useBluetoothDevice {
            // If NMEA stream is not running
                // Start NMEA
                nmea = NMEA()
                nmea!.startNMEA()
        } else {
            // If default GPS is not active
                // Use default GPS
                clLocationHelper = LocationHelper()
        }
    }
    
}
