//
//  SelectTripModeView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/1/24.
//

import SwiftUI

struct SelectTripModeView: View {
    
    // Bridging coordinator
//    @EnvironmentObject var gpsBridgingCoordinator: GpsBridgingCoordinator
//    @EnvironmentObject var cameraBridgingCoordinator: CameraBridgingCoordinator
//    @EnvironmentObject var mapBridgingCoordinator: MapBridgingCoordinator
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    
    
    var body: some View {
        
        NavigationStack{
            List {
                // Fast Acquisition
//                NavigationLink {
//                    SelectTripView(tripMode: "fast")
//                        .navigationTitle("🐇 Select or Create a Trip")
//                } label: {
//                    HStack {
//                        Image(systemName: "hare.fill").bold(false).foregroundColor(.gray)
//                        Text("Fast Acquisition")
//                    }
//                }
                // Thorough Acquisition
                NavigationLink {
                    SelectTripView(map: map, gps: gps, camera: camera, tripMode: "thorough")
                        .navigationTitle("🐢 Select or Create a Trip")
//                        .environmentObject(gpsBridgingCoordinator)
//                        .environmentObject(mapBridgingCoordinator)
//                        .environment(gps)
//                        .environmentObject(cameraBridgingCoordinator)
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
