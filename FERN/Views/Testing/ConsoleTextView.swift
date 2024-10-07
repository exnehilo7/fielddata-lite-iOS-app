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
    
    // Restart Arrow button
    var restartArrowViaStartNMEAButton: some View {
        Button(action: {
            gps.restartArrowViaStartNMEAWithEventDefaults()
        },
               label: {HStack {
            Image(systemName: "arrow.uturn.right.circle").font(.system(size: 15))
            Text("Restart Arrow").font(.system(size: 15))
        }
               .frame(minWidth: 95, maxWidth: 100, minHeight: 0, maxHeight: 50)
               .background(Color.green)
               .foregroundColor(.white)
               .cornerRadius(10)
               .padding().padding()
        })
    }
    var restartArrowViaRESTARTNMEAButton: some View {
        Button(action: {
            gps.restartArrowViaRESTARTNMEA()
        },
               label: {HStack {
            Image(systemName: "arrow.circlepath").font(.system(size: 15))
            Text("Start Arrow as if app first opened").font(.system(size: 15))
        }
               .frame(minWidth: 95, maxWidth: 100, minHeight: 0, maxHeight: 50)
               .background(Color.blue)
               .foregroundColor(.white)
               .cornerRadius(10)
               .padding().padding()
        })
    }
    
    var body: some View {
        TextEditor(text: .constant(gps.nmea?.consoleText ?? "No Console String"))
            .foregroundStyle(.secondary)
            .font(.system(size: 12)).padding(.horizontal)
            .frame(minHeight: 800, maxHeight: 800)
            .fixedSize(horizontal: false, vertical: true)
            .onChange(of: scenePhase) {phase in
                if phase == .active {
                    gps.nmea?.appendToTextEditor(text: "active")
//                    gps.startArrow()
                } else if phase == .inactive {
                    gps.nmea?.appendToTextEditor(text: "inactive")
                } else if phase == .background {
                    gps.nmea?.appendToTextEditor(text: "background")
//                    gps.stopArrow()
                }
            }
        
        
    }
    
}
