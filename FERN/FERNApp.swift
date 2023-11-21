//
//  FERNApp.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.
//

import SwiftUI

@main //SearchByNameView?
struct FERNApp: App {
    
//    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                StartScreenView()//.environment(\.managedObjectContext, persistenceController.container.viewContext)
           }
        }
    }
}
