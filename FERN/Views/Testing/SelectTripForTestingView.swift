//
//  SelectTripForTestingView.swift
//  FERN
//
//  Created by Hopp, Dan on 7/30/24.
//

import SwiftUI
import SwiftData

struct SelectTripForTestingView: View {
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    var upload: FileUploadClass
    
    // For add-a-trip popup
    @State private var showingTripNameAlert = false
    @State private var showingDeleteTripAlert = false
    @State private var name = ""
    
    @Environment(\.modelContext) var modelContext // swift data
    @Query var sdTrips: [SDTrip]
    @Query var settings: [Settings]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sdTrips) { item in
                    NavigationLink {
                        // Try to prevent data race by passing swiftdata values(?)
                        FileUploadTestingView(tripName: item.name, upload: upload)
                    } label: {
                        HStack{
                            Text(item.name)
                        }
                    }
                }
            }
        }
    }
}
