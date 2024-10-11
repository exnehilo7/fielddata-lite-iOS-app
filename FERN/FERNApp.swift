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
//    var container: ModelContainer
//
//    init() {
//        do {
//            container = try ModelContainer(for: Settings.self, SDTrip.self //,migrationPlan: SettingsMigrationPlan.self  APR-2024: SwiftData may still be too immature. OCT-2024: Apparently auto-migration was a thing whose documentation had little web saturation per anything foundational with Apple, or it was added to iOS MAY 2024.
//            )
//        } catch {
//                fatalError("Failed to configure SwiftData container.")
//            }
//        }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Settings.self,
            SDTrip.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                StartScreenView()
            }
        //        }.modelContainer(container)
        //            .modelContainer(for: Settings.self)
        //            .modelContainer(for: SDTrip.self)
        }.modelContainer(sharedModelContainer)
    }
}
