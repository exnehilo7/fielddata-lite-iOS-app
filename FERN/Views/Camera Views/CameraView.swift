//
//  CameraView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/17/24.
//
//  17-JUN-2024: Replaces TripModeThoroughCameraView

import SwiftUI

struct CameraView: View {
    
    
//    // MOVE THESE TO A SOME VIEW DECLARATION CONTROLLED BY useBluetoothDevice?
//    var clLat:String {
//        return "\(gpsBridgingCoordinator.gpsController.clLocationHelper?.lastLocation?.coordinate.latitude ?? 0.0000)"
//    }
//    var clLong:String {
//        return "\(gpsBridgingCoordinator.gpsController.clLocationHelper?.lastLocation?.coordinate.longitude ?? 0.0000)"
//    }
//    var clHorzAccuracy:String {
//        return "\(gpsBridgingCoordinator.gpsController.clLocationHelper?.lastLocation?.horizontalAccuracy ?? 0.00)"
//    }
//    var clVertAccuracy:String {
//        return "\(gpsBridgingCoordinator.gpsController.clLocationHelper?.lastLocation?.verticalAccuracy ?? 0.00)"
//    }
//    var clAltitude:String {
//        return "\(gpsBridgingCoordinator.gpsController.clLocationHelper?.lastLocation?.altitude ?? 0.0000)"
//    }
//    //------------------------------------------------------------------
//
//    
//    //MARK: View code from TripModeThoroughCameraView
//    // GPS Data Display ------------------------------------------------
//    // Arrow Gold
//    var arrowGpsData: some View {
//        VStack {
//            
//            Label("EOS Arrow Gold", systemImage: "antenna.radiowaves.left.and.right").underline().foregroundColor(.yellow)
//            //            Text("Protocol: ") + Text(gpsBridgingCoordinator.gpsController.nmea?.protocolText as String)
//            Text("Latitude: ") + Text(gpsBridgingCoordinator.gpsController.nmea?.latitude ?? "0.0000")
//            Text("Longitude: ") + Text(gpsBridgingCoordinator.gpsController.nmea?.longitude ?? "0.0000")
//            Text("Altitude (m): ") + Text(gpsBridgingCoordinator.gpsController.nmea?.altitude ?? "0.00")
//            Text("Horizontal Accuracy (m): ") + Text(gpsBridgingCoordinator.gpsController.nmea?.accuracy ?? "0.00")
//            Text("GPS Used: ") + Text(gpsBridgingCoordinator.gpsController.nmea?.gpsUsed ?? "No GPS")
//        }.font(.system(size: 18))//.foregroundColor(.white)
//    }
//    
//    // iOS Core Location
//    var coreLocationGpsData: some View {
//        VStack {
//            
//            Label("Standard GPS",  systemImage: "location.fill").underline().foregroundColor(.blue)
//            Text("Latitude: ") + Text("\(clLat)")
//            Text("Longitude: ") + Text("\(clLong)")
//            Text("Altitude (m): ") + Text("\(clAltitude)")
//            Text("Horizontal Accuracy (m): ") + Text("\(clHorzAccuracy)")
//            Text("Vertical Accuracy (m): ") + Text("\(clVertAccuracy)")
//        }.font(.system(size: 15))//.foregroundColor(.white)
//            .padding()
//    }
//    //------------------------------------------------------------------
    
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}
