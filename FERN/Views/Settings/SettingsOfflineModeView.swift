//
//  SettingsOfflineModeView.swift
//  FERN
//
//  Created by Hopp, Dan on 9/24/24.
//
//  If offline is toggled on, clear out and write to .txt files within a "cache" folder. Have files for routing and view trip menu items, and map coordinates for each of the menu items.
//
//  Until the Sep 2024 Transect trip is finished and all files moved to the server, use a button to trigger the file write.

import SwiftUI

struct SettingsOfflineModeView: View {
    
    @Bindable var setting: Settings
    
    
    var body: some View {
        Text("Under development")
//        Toggle("Use Bluetooth Device", isOn: $setting.)
//            .onChange(of: setting.) {
//            }
    }
}
