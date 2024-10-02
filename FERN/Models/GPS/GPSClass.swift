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
                print("Lifecycle Print: nmea is nil")
                nmea = NMEA()
                print("Lifecycle Print: calling nmea!.startNMEA()")
                nmea!.startNMEA()
            } else {print("Lifecycle Print: nmea is NOT nil")}
        } else {
            
            // Check if default GPS is not active? If not then, use default GPS
            if clLocationHelper == nil {
                print("Lifecycle Print: starting iOS GPS")
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
                print("Lifecycle Print: Stopping NMEA")
                nmea?.endStreaming()
                nmea = nil
            }
        } else {
            // If default GPS is not active
            print("Lifecycle Print: Stopping standard GPS")
            clLocationHelper!.stopUpdatingDefaultCoreLocation()
        }
        
        // Toggle back device feed
        UIApplication.shared.isIdleTimerDisabled = false
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
    
    func restartArrow() async {
        if nmea != nil {
            print("Lifecycle Print: Restarting NMEA")
//            Task {
//                nmea?.endStreaming()
//            }
//            nmea = NMEA()
            nmea!.restartNMEA()
        } else {
            print("Lifecycle Print: nmea variable in GPSClass is already nil")
        }
    }
    
    func startStartArrow() async {
        if nmea != nil {
            print("Lifecycle Print: Start-starting NMEA")
            nmea!.startNMEA()
        } else {
            print("Lifecycle Print: nmea variable in GPSClass is already nil")
        }
    }
    
}
