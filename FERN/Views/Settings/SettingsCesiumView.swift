//
//  SettingsCesiumView.swift
//  FERN
//
//  Created by Hopp, Dan on 4/24/24.
//

import SwiftUI
import SwiftData

struct SettingsCesiumView: View {
    @Environment(\.modelContext) var modelContext
    
    //    @Query var settings: [Settings]
    @Bindable var setting: Settings
    
    var body: some View {
        Form {
            TextField("URL", text: $setting.cesiumURL)
        }
        .navigationTitle("Edit CesiumJS Info")
        .navigationBarTitleDisplayMode(.inline)
//        NavigationStack {
//            List {
//                ForEach(settings) { item in
//                    NavigationLink(item.cesiumURL){
//                        EditCesiumView(setting: item)
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
