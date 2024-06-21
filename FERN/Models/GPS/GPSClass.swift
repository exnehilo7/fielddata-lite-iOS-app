//
//  GPSClass.swift
//  FERN
//
//  Created by Hopp, Dan on 6/20/24.
//
//  Uses CoreLocation and NMEAData classes

import SwiftUI
import SwiftData

// ViewController which contains functions that need to be called from SwiftUI
@Observable class GpsClass {
    
    var nmea: NMEA?
    var clLocationHelper: LocationHelper?

    func startGPSFeed(settings: [Settings]) {
        if settings[0].useBluetoothDevice {
            // Check NMEA stream? In not running, then start NMEA
                // Start NMEA
                if nmea == nil {
                    nmea = NMEA()
                    nmea!.startNMEA()
                }
        } else {
            // Check if default GPS is not active? If not then, use default GPS
            // Use default GPS
            if clLocationHelper == nil {
                clLocationHelper = LocationHelper()
            }
        }
        
        // Don't put device to sleep while GPS is running
        UIApplication.shared.isIdleTimerDisabled = true
        
    }
    
    // This func will need some work (does it need to be used at all?)
    func stopGPSFeed(settings: [Settings]) {
        
        if settings[0].useBluetoothDevice {
            // Check NMEA stream?
                if nmea != nil {
                    print("Stopping NMEA")
                    setNmeaVarToNil()
                }
        } else {
            // If default GPS is not active
                // Use default GPS
                print("Stopping standard GPS")
                clLocationHelper!.stopUpdatingDefaultCoreLocation()
        }
        
        // Toggle back device feed
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func setNmeaVarToNil(){
        nmea = nil
    }
    
}
