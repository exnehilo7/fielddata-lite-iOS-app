//
//  SettingsDatabaseView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/16/24.
//

import SwiftUI
import SwiftData


struct SettingsDatabaseView: View {
    
    @Environment(\.modelContext) var modelContext
    
    //    @Query var settings: [Settings]
    @Bindable var setting: Settings
    
    var body: some View {
        Form {
            TextField("URL", text: $setting.databaseURL)
        }
        .navigationTitle("Edit Database Info")
        .navigationBarTitleDisplayMode(.inline)
//        NavigationStack {
//            List {
//                ForEach(settings) { item in
//                    NavigationLink(item.databaseURL){
//                        EditDatabaseView(setting: item)
//                    }
//                }
//            }
////            .toolbar {
////                Button("Add URL", action: addValue)
////            }
//        }
    }
    
//    func addValue() {
//        // Only add one
//        if settings.count < 1 {
//            modelContext.insert(Settings())
//        }
//    }
    
}
