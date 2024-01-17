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
                // Select a saved route
                NavigationLink {
                    SettingsDatabaseView()
                        .navigationTitle("Database URL")
                } label: {
                    HStack {
                        Image(systemName: "network").bold(false).foregroundColor(.gray)
                        Text("Database URL")
                    }
                }
                // Search within an area
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

