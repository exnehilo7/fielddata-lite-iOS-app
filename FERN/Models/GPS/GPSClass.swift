//
//  GPSClass.swift
//  FERN
//
//  Created by Hopp, Dan on 6/20/24.
//
//  Uses CoreLocation and NMEAData classes

import SwiftUI
import SwiftData

@Observable class GpsClass {
    
    var nmea: NMEA?
    var clLocationHelper: LocationHelper?

    func startGPSFeed(settings: [Settings]) {
        if settings[0].useBluetoothDevice {
            // Check NMEA stream? In not running, then start NMEA
            if nmea == nil { // Try button to "refresh" nmea connection when GPS signal is lost in an area under a lot of trees
                nmea = NMEA()
                nmea!.startNMEA()
            }
        } else {
            // Check if default GPS is not active? If not then, use default GPS
            if clLocationHelper == nil {
                clLocationHelper = LocationHelper()
            }
        }
        
        // Don't put device to sleep while GPS is running
        UIApplication.shared.isIdleTimerDisabled = true
        // Activate battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        
    }
    
    // This func will need some work (does it need to be used at all?)
    func stopGPSFeed(settings: [Settings]) {
        
        if settings[0].useBluetoothDevice {
            // Check NMEA stream
            if nmea != nil {
                print("Stopping NMEA")
                nmea?.endStreaming()
                nmea = nil
            }
        } else {
            // If default GPS is not active
            print("Stopping standard GPS")
            clLocationHelper!.stopUpdatingDefaultCoreLocation()
        }
        
        // Toggle back device feed
        UIApplication.shared.isIdleTimerDisabled = false
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
    
    func restartArrow(settings: [Settings]) async {
        if nmea != nil {
            print("Restarting NMEA")
//            nmea?.endStreaming()
            nmea = NMEA()
            nmea!.startNMEA()
        } else {
            print("nmea variable in GPSClass is already nil")
        }
    }
    
}
