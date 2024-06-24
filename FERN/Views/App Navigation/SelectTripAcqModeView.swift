//
//  SelectTripAcqModeView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/1/24.
//
//  Created to select different trip acquisition speeds (less button presses vs. more).
//  24-JUN-2024: Disable for now

import SwiftUI

struct SelectTripAcqModeView: View {
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    
    
    var body: some View {
        
        NavigationStack{
            List {
                // Thorough Acquisition
                NavigationLink {
                    SelectTripView(map: map, gps: gps, camera: camera) //, tripMode: "thorough")
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
