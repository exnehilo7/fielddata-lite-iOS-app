//
//  EditDatabaseView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/16/24.
//
//  10-JUN-2024: This view is no longer required(?)

import SwiftUI
import SwiftData

struct EditDatabaseView: View {
    
    @Bindable var setting: Settings
    
    var body: some View {
        Form {
            TextField("URL", text: $setting.databaseURL)
        }
        .navigationTitle("Edit Database Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}
