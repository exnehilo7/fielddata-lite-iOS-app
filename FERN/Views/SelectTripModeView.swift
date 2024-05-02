//
//  SelectTripModeView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/1/24.
//

import SwiftUI

struct SelectTripModeView: View {
    
    @StateObject var nmea = NMEA()
    
    @State private var gpsModeIsSelected = false
    @State private var useArrowGold = false
    
    // Select GPS mode
    var selectGpsMode: some View {
        HStack {
            HStack{
                Button{
                    gpsModeIsSelected = true
                } label: {
                    Label("Use Standard GPS", systemImage: "location.fill")
                }.buttonStyle(.borderedProminent)
            }.padding(.leading, 20)
            Spacer()
            HStack{
                Button{
                    useArrowGold = true
                    gpsModeIsSelected = true
                    //Start NMEA feed here?
                    nmea.viewDidLoad()
                } label: {
                    Label("Use Arrow Gold Device", systemImage: "antenna.radiowaves.left.and.right").foregroundColor(.black)
                }.buttonStyle(.borderedProminent).tint(.yellow)
            }.padding(.trailing, 20)
        }
    }
    
    var navStack: some View {
        NavigationStack{
            List {
                    // Camera
                    NavigationLink {
                        SelectTripView(useArrowGold: useArrowGold, gpsModeIsSelected: gpsModeIsSelected)
                            .navigationTitle("Camera").environmentObject(nmea)
                    } label: {
                        HStack {
                            Image(systemName: "camera").bold(false).foregroundColor(.gray)
                            Text("Camera")
                        }
                    }
                    // List of trips in the database
                    NavigationLink {
                        TripsInDBView(showArrowGold: useArrowGold, gpsModeIsSelected: gpsModeIsSelected)
                            .navigationTitle("Select a Map Type").environmentObject(nmea)
                    } label: {
                        HStack {
                            Image(systemName: "externaldrive").bold(false).foregroundColor(.gray)
                            Text("Trips in Database")
                        }
                    }
                }
        }.bold().onAppear(perform:{ UIApplication.shared.isIdleTimerDisabled = false})//.environmentObject(nmea)
    }
    
    // Main body
    var body: some View {
        if gpsModeIsSelected {
            navStack
        } else {
            selectGpsMode
        }
        
    }
}
