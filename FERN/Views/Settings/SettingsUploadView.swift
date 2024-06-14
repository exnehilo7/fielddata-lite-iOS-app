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
    
    @Bindable var setting: Settings
    
    var body: some View {
        Form {
            TextField("URL", text: $setting.uploadScriptURL)
        }.navigationTitle("Edit Upload Info")
            .navigationBarTitleDisplayMode(.inline)
    }
    
}
