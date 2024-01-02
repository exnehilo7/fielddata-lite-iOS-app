//
//  CompletedTripView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/2/24.
//

import SwiftUI

struct CompletedTripView: View {
    
    // From calling view
    var tripName: String
    
    var body: some View {
        Text("Trip \(tripName) is completed!")
    }
}

