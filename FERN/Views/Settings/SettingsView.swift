//
//  SettingsView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/16/24.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    var body: some View {
        NavigationStack{
            List {
                // CesiumJS URL
                NavigationLink {
                    SettingsCesiumView(setting: settings[0])
                        .navigationTitle("CesiumJS URL")
                } label: {
                    HStack {
                        Image(systemName: "ellipsis.curlybraces").bold(false).foregroundColor(.gray)
                        Text("CesiumJS URL")
                    }
                }
                // Database URL
                NavigationLink {
                    SettingsDatabaseView(setting: settings[0])
                        .navigationTitle("Database URL")
                } label: {
                    HStack {
                        Image(systemName: "externaldrive").bold(false).foregroundColor(.gray)
                        Text("Database URL")
                    }
                }
                // PHP upload script
                NavigationLink {
                    SettingsUploadView(setting: settings[0])
                        .navigationTitle("Upload Script URL")
                } label: {
                    HStack {
                        Image(systemName: "ellipsis.curlybraces").bold(false).foregroundColor(.gray)
                        Text("Upload Script URL")
                    }
                }
                // HDOP Threshold
                NavigationLink {
                    SettingsHdopView(setting: settings[0])
                        .navigationTitle("GPS Settings")
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3").bold(false).foregroundColor(.gray)
                        Text("GPS Settings")
                    }
                }
            }
        }
    }
}

