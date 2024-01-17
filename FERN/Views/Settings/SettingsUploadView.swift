//
//  SettingsUploadView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/16/24.
//

import SwiftUI
import SwiftData

struct SettingsUploadView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var settings: [Settings]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(settings) { item in
                    NavigationLink(item.uploadScriptURL){
                        EditDatabaseView(setting: item)
                    }
                }//.onDelete(perform: deleteItem)  // For testing
            }
            .toolbar {
                Button("Add URL", action: addValue)
            }
        }
    }
    
    func addValue() {
        // Only add one
        if settings.count < 1 {
            modelContext.insert(Settings())
        }
    }
    
//    func deleteItem(_ indexSet: IndexSet) {
//        for index in indexSet {
//            let destination = settings[index]
//            modelContext.delete(destination)
//        }
//    }
    
}
