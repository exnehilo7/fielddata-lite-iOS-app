//
//  NMEADataView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/15/23.
//

import SwiftUI

struct NMEADataView: View {
    @ObservedObject var nmea:NMEA = NMEA()
    @State var toggleArrowGold = false
    
    @ObservedObject var clLocationHelper = LocationHelper()
    var clLat:String {
        return "Latitude: \(clLocationHelper.lastLocation?.coordinate.latitude ?? 0.0000)"
    }
    var clLong:String {
        return "Longitude: \(clLocationHelper.lastLocation?.coordinate.longitude ?? 0.0000)"
    }
    var clHorzAccuracy:String {
        return "Horizontal Accuracy (m): \(clLocationHelper.lastLocation?.horizontalAccuracy ?? 0.00)"
    }
    var clVertAccuracy:String {
        return "Vertical Accuracy (m): \(clLocationHelper.lastLocation?.verticalAccuracy ?? 0.00)"
    }
    var clAltitude:String {
        return "Altitude (m): \(clLocationHelper.lastLocation?.altitude ?? 0.0000)"
    }
    
    var body: some View {
        // Toggle for GPS modes
//        Toggle("Toggle off iOS Location services (recommended when Arrow Gold is in use)", isOn: $toggleArrowGold)
        Spacer()
//        if toggleArrowGold {
            VStack {
                // Arrow Gold
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Label("Arrow Gold GPS",  systemImage: "bolt.fill").labelStyle(.titleOnly)
                Button("Start the Arrow Gold stream") {
                    nmea.viewDidLoad() // nmea on
                    clLocationHelper.stopUpdatingDefaultCoreLocation() // basic core off
//                    clLat = "0.0000"  // computed properties are a get-only property??
                }.buttonStyle(.borderedProminent)
                Text("Protocol: ") + Text(nmea.protocolText as String)
                Text("Latitude: ") + Text(nmea.latitude ?? "0.0000")
                Text("Longitude: ") + Text(nmea.longitude ?? "0.0000")
                Text("Altitude: ") + Text(nmea.altitude ?? "0.00")
                Text("Horizontal Accuracy: ") + Text(nmea.accuracy ?? "0.00")
                Text("GPS Used: ") + Text(nmea.gpsUsed ?? "No GPS")
            }.font(.system(size: 20))//.onAppear(perform: {})
//        }
//        else {
            Divider()
            VStack {
                // Default Core Location
                Image(systemName: "location.fill")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Label("iOS Core Location",  systemImage: "bolt.fill").labelStyle(.titleOnly)
                Button("Start the iOS Location Services stream") {
                    nmea.stopUpdatingArrowCoreLocation() // nmea off
                    clLocationHelper.startUpdatingDefaultCoreLocation() // basic core on
                }.buttonStyle(.borderedProminent)
                Text("\(clLat)")
                Text("\(clLong)")
                Text("\(clAltitude)")
                Text("\(clHorzAccuracy)")
                Text("\(clVertAccuracy)")
            }.font(.system(size: 20))
                .padding()//.onAppear(perform: {})
//        }
        Spacer()
    }
}

//struct NMEADataView_Previews: PreviewProvider {
//    static var previews: some View {
//        NMEADataView()
//    }
//}
