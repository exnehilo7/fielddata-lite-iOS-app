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
                    SelectTripView(tripMode: "thorough")
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
