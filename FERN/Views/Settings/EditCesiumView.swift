//
//  EditCesiumView.swift
//  FERN
//
//  Created by Hopp, Dan on 4/24/24.
//
//  10-JUN-2024: This view is no longer required(?)

import SwiftUI
import SwiftData

struct EditCesiumView: View {
    @Bindable var setting: Settings
    
    var body: some View {
        Form {
            TextField("URL", text: $setting.cesiumURL)
        }
        .navigationTitle("Edit CesiumJS Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}
