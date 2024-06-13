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
    
//    @Query var settings: [Settings]
    @Bindable var setting: Settings
    
    var body: some View {
        Form {
            TextField("URL", text: $setting.uploadScriptURL)
        }.navigationTitle("Edit Upload Info")
            .navigationBarTitleDisplayMode(.inline)
//        NavigationStack {
//            List {
////                ForEach(settings) { item in
//                    NavigationLink(settings[0].uploadScriptURL){
//                        EditUploadView(setting: settings[0])
//                    }
////                }
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
