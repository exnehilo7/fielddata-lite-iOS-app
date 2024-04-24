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
    
    @Query var settings: [Settings]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(settings) { item in
                    NavigationLink(item.cesiumURL){
                        EditCesiumView(setting: item)
                    }
                }
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
    
}
