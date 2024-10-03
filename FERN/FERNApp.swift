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
    let audio = playSound()

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
                if phase == .inactive {
                    // inactive short_double_low.caf
                    audio.playInactive()
                } else if phase == .active {
                    // active short_double_high.caf jbl_begin_short_carplay.caf
                    audio.playActive()
                } else if phase == .background {
                    // background MediaPaused.caf
                    audio.playBackground()
                }
            }
    }
}
