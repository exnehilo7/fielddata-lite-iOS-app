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
    
    // Sounds
    let audio = playSound()

    func startGPSFeed(settings: [Settings]) {
        if settings[0].useBluetoothDevice {
            startArrow()
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
            stopArrow()
//            // Check NMEA stream
//            if nmea != nil {
////                print("NMEA endStreaming")
////                nmea?.endStreaming()
//                print("setting nmea to nil")
//                nmea = nil
//            }
        } else {
            // If default GPS is not active
            print("stopUpdatingDefaultCoreLocation")
            clLocationHelper!.stopUpdatingDefaultCoreLocation()
        }
        
        UIApplication.shared.isIdleTimerDisabled = false
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
    
    func restartArrowViaStartNMEA() {
        if nmea != nil {
            print("GPS Class 'nmea' var is not nil. Restarting NMEA via startNMEA().")
            print(#function,"::","GPS Class 'nmea' var is not nil. Restarting NMEA via startNMEA().", to: &logger)
            nmea!.startNMEA()
        } else {
            print("No restart, 'nmea' variable in GPS Class is already nil")
        }
    }
    
    func restartArrowViaRESTARTNMEA() {
        if nmea != nil {
            print("GPS Class 'nmea' var is not nil. Restarting NMEA via reStartNMEA().")
            print(#function,"::","GPS Class 'nmea' var is not nil. Restarting NMEA via reStartNMEA().", to: &logger)
            nmea!.reStartNMEA()
        } else {
            print("No restart, 'nmea' variable in GPS Class is already nil")
        }
    }
    
    func startArrow() {
        // Check NMEA stream? In not running, then start NMEA
        if nmea == nil {
            nmea = NMEA()
            nmea!.startNMEA()
        } else {
            print("No startNMEA() called, 'nmea' variable in GPS Class was NOT nil")
            print(#function,"::","No startNMEA() called, 'nmea' variable in GPS Class was NOT nil", to: &logger)
        }
    }
    
    func stopArrow() {
        if nmea != nil { 
            print("setting CPS Class 'nmea' var to nil")
            print(#function,"::","setting CPS Class 'nmea' var to nil", to: &logger)
            nmea = nil
        }
    }
}
