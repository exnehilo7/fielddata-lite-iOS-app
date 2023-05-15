//
//  NMEADataView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/15/23.
//

import SwiftUI

struct NMEADataView: View {
    @ObservedObject var nmea:NMEA = NMEA()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Button("Start the Arrow Gold stream") {
                nmea.viewDidLoad()
            }.buttonStyle(.borderedProminent)
            Text("Any nmea values?")
            Text("Protocol: ") + Text(nmea.protocolText as? String ?? "No Protocol")
            Text("Latitude: ") + Text(nmea.latitude ?? "0.0000")
            Text("Longitude: ") + Text(nmea.longitude ?? "0.0000")
            Text("Altitude: ") + Text(nmea.altitude ?? "0.00") + Text(" (m)")
            Text("Accuracy: ") + Text(nmea.accuracy ?? "0.00")
            Text("GPS Used: ") + Text(nmea.gpsUsed ?? "No GPS")
        }
        .padding()
    }
}

//struct NMEADataView_Previews: PreviewProvider {
//    static var previews: some View {
//        NMEADataView()
//    }
//}
