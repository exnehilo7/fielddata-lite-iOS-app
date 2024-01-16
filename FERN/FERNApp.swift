//
//  FERNApp.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.
//

import SwiftUI
import SwiftData

@main //SearchByNameView?
struct FERNApp: App {
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                StartScreenView()
           }
        }.modelContainer(for: Settings.self)
    }
}
