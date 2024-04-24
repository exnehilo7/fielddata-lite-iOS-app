//
//  FERNApp.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.
//

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
