//
//  EditDatabaseView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/16/24.
//

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
