//
//  FERNApp.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.
//
//  Classes are reference types. Structs are value types.
//
//  Note that the supplied NMEA toolkit was not compiled with the required arm for a live preview within XCode.

import SwiftUI
import SwiftData

@main
struct FERNApp: App {
    
    // Send multiple model configurations into a single model container
    var container: ModelContainer

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
    }
}
