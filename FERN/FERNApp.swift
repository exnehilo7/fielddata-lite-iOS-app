//
//  FERNApp.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.
//
//  Note that the supplied NMEA toolkit was not compiled with the required arm for a live preview within XCode.

import SwiftUI
import SwiftData

@main
struct FERNApp: App {
    
    // Send multiple model configurations into a single model container
    var container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase // to see the app's phases
    
    // Sounds
//    let audio = playSound()

    init() {
        do {
            container = try ModelContainer(for: Settings.self, SDTrip.self //,migrationPlan: SettingsMigrationPlan.self  APR-2024: SwiftData may still be too immature
            )
        } catch {
                fatalError("Failed to configure SwiftData container.")
            }
        }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                StartScreenView()
            }
        }.modelContainer(container)
            .onChange(of: scenePhase) {phase in
                print(phase)
//                if phase == .active {
//                    audio.playActive()
//                } else if phase == .inactive {
//                    audio.playInactive()
//                } else if phase == .background {
//                    audio.playBackground()
//                }
            }
    }
}
