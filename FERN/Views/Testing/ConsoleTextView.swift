//
//  ConsoleTextView.swift
//  FERN
//
//  Created by Hopp, Dan on 10/4/24.
//

import SwiftUI
import SwiftData

struct ConsoleTextView: View {
    
    var gps: GpsClass
    @Environment(\.scenePhase) private var scenePhase
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    var manuallyStartGPS: some View {
        // Manual GPS start
        Button(action: {
            gps.startGPSFeed(settings: settings)
        },
        label: {
            HStack {
                Image(systemName: "play").font(.system(size: 11))
                Text("Manually Start GPS").font(.system(size: 11))
            }
           .frame(minWidth: 95, maxWidth: 200, minHeight: 20, maxHeight: 50)
           .background(Color.green)
           .foregroundColor(.white)
           .cornerRadius(10)
           .padding()
        })
    }
    
    // Arrow Restart buttons
    var restartArrowViaStartNMEAButton: some View {
        Button(action: {
            gps.restartArrowViaStartNMEA()
        },
               label: {HStack {
            Image(systemName: "arrow.uturn.right").font(.system(size: 11))
            Text("Restart Arrow via startNMEA()").font(.system(size: 11))
        }
               .frame(minWidth: 95, maxWidth: 200, minHeight: 20, maxHeight: 50)
               .background(Color.yellow)
               .foregroundColor(.black)
               .cornerRadius(10)
        })
    }
    var restartArrowViaRESTARTNMEAButton: some View {
        Button(action: {
            gps.restartArrowViaRESTARTNMEA()
        },
               label: {HStack {
            Image(systemName: "arrow.circlepath").font(.system(size: 11))
            Text("Restart Arrow via reStartNMEA()").font(.system(size: 11))
        }
               .frame(minWidth: 95, maxWidth: 200, minHeight: 20, maxHeight: 50)
               .background(Color.blue)
               .foregroundColor(.white)
               .cornerRadius(10)
               .padding()
        })
    }
    
    var body: some View {
//        TextEditor(text: .constant(gps.nmea?.consoleText ?? "No Console String"))
//            .foregroundStyle(.secondary)
//            .font(.system(size: 12)).padding(.horizontal)
//            .frame(minHeight: 600, maxHeight: 600)
//            .fixedSize(horizontal: false, vertical: true)
//            .onChange(of: scenePhase) {phase in
//                if phase == .active {
//                    gps.nmea?.appendToTextEditor(text: "active")
////                    gps.startArrow()
//                } else if phase == .inactive {
//                    gps.nmea?.appendToTextEditor(text: "inactive")
//                } else if phase == .background {
//                    gps.nmea?.appendToTextEditor(text: "background")
////                    gps.stopArrow()
//                }
//            }
        manuallyStartGPS
        restartArrowViaStartNMEAButton
        restartArrowViaRESTARTNMEAButton
    }
    
}
