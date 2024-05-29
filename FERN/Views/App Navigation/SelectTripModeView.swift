//
//  SelectTripModeView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/1/24.
//

import SwiftUI

struct SelectTripModeView: View {
    var body: some View {
        
        NavigationStack{
            List {
                // Select Trip
                NavigationLink {
                    SelectTripView(tripMode: "fast")
                        .navigationTitle("Select or Create a Trip")
                } label: {
                    HStack {
                        Image(systemName: "hare.fill").bold(false).foregroundColor(.gray)
                        Text("Fast Acquisition")
                    }
                }
                // Select a saved route
                NavigationLink {
                    SelectTripView(tripMode: "thorough")
                        .navigationTitle("Select or Create a Trip")
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
