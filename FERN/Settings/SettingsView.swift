//
//  SettingsView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/16/24.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack{
            List {
                // CesiumJS URL
                NavigationLink {
                    SettingsCesiumView()
                        .navigationTitle("CesiumJS URL")
                } label: {
                    HStack {
                        Image(systemName: "ellipsis.curlybraces").bold(false).foregroundColor(.gray)
                        Text("CesiumJS URL")
                    }
                }
                // Database URL
                NavigationLink {
                    SettingsDatabaseView()
                        .navigationTitle("Database URL")
                } label: {
                    HStack {
                        Image(systemName: "externaldrive").bold(false).foregroundColor(.gray)
                        Text("Database URL")
                    }
                }
                // PHP upload script
                NavigationLink {
                    SettingsUploadView()
                        .navigationTitle("Upload Script URL")
                } label: {
                    HStack {
                        Image(systemName: "ellipsis.curlybraces").bold(false).foregroundColor(.gray)
                        Text("Upload Script URL")
                    }
                }
            }
        }
    }
}

