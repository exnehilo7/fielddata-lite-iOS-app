//
//  SelectTripModeView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/1/24.
//

import SwiftUI

struct SelectTripModeView: View {
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    
    
    var body: some View {
        
        NavigationStack{
            List {
                // Thorough Acquisition
                NavigationLink {
                    SelectTripView(map: map, gps: gps, camera: camera, tripMode: "thorough")
                        .navigationTitle("🐢 Select or Create a Trip")
                } label: {
                    HStack {
                        Image(systemName: "tortoise.fill").bold(false).foregroundColor(.gray)
                        Text("Thorough Acquisition")
                    }
                }
            }
        }
    }
}
