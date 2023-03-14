//
//  GPSFeedView.swift
//  FERN
//
//  Created by Hopp, Dan on 3/9/23.
//

import SwiftUI

struct GPSFeedView: View {
    
    @State var latitude: String
    @State var longitude: String
    @State var altitude: String
    @State var xyAccuracy: String
    @State var gpsUsed: String
    @State var receiveText: [deviceFeedItem] = []
    
    @State private var requestLocation = true
    
    // Will it need inits?
    
    
    struct deviceFeedItem: Identifiable {
        let id = UUID()
        var stream = ""
    }
    
    var body: some View {
        // VStack for all
        VStack{
            //HStack for views
            HStack {
                //VStack for lat, long, alt, XYAcc, GPS used
                VStack {
                    //HStacks for key:value
                    HStack {
                        Label("Latitude:", systemImage: "star")
                            .font(.title)
                            .labelStyle(.titleOnly)
                        Spacer()
                        Text(latitude).font(.title)
                    }.padding(.leading, 40)
                    HStack {
                        Label("Longitude:", systemImage: "star")
                            .font(.title)
                            .labelStyle(.titleOnly)
                        Spacer()
                        Text(longitude).font(.title)
                    }.padding(.leading, 40)
                    HStack {
                        Label("Altitude:", systemImage: "star")
                            .font(.title)
                            .labelStyle(.titleOnly)
                        Spacer()
                        Text(altitude).font(.title)
                    }.padding(.leading, 40)
                    HStack {
                        Label("XY Accuracy:", systemImage: "star")
                            .font(.title)
                            .labelStyle(.titleOnly)
                        Spacer()
                        Text(xyAccuracy).font(.title)
                    }.padding(.leading, 40)
                    HStack {
                        Label("GPS/GNSS Used:", systemImage: "star")
                            .font(.title)
                            .labelStyle(.titleOnly)
                        Spacer()
                        Text(gpsUsed).font(.title)
                    }.padding(.leading, 40)
                }
                Divider().frame(height: 200)
                //VStack for Button and Toggle
                VStack {
                    HStack{
                        Spacer()
                        Button("BT Accessories"){
                            
                        }.font(.title)
                    }
                    Toggle("Request Location", isOn: $requestLocation).font(.title).padding(.top, 80)
                }.padding(.trailing, 40).padding(.leading, 40)
            }
            // Device feed
            List {
                ForEach(receiveText) { item in
                    Text(item.stream)
                }
            }
            // Pause button
            HStack{
                Spacer()
                Button("Pause"){
                    
                }.font(.title).padding(.trailing, 40)
            }
        }
    }
}

struct GPSFeedView_Previews: PreviewProvider {
    static var previews: some View {
        GPSFeedView(latitude: "-00.00000000", longitude: "-00.00000000", altitude: "-00.00 M", xyAccuracy: "-00.00000000", gpsUsed: "00")
    }
}
