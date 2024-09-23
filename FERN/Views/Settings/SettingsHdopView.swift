//
//  SettingsHdopView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/10/24.
//

import SwiftUI
import SwiftData

struct SettingsHdopView: View {
    
    @Bindable var setting: Settings
    var camera: CameraClass
    
    @Environment(\.modelContext) var modelContext
    
    @State private var min: Double = 0
    @State private var max: Double = 2.0

    var body: some View {

        Spacer()
        HStack {
            Spacer()
            if !camera.showHDOPSettingView {
                Toggle("Use Bluetooth Device", isOn: $setting.useBluetoothDevice)
                    .onChange(of: setting.useBluetoothDevice) {
                        if !setting.useBluetoothDevice {
                            max = 40.0
                            setting.hdopThreshold = 10.0
                        } else {
                            max = 2.0
                            setting.hdopThreshold = 0.2
                        }
                    }.onAppear(perform: {
                        if !setting.useBluetoothDevice{
                            max = 40.0
                        }
                        else {
                            max = 2.0
                        }
                    })
            }
            Spacer()
        }
        Spacer()
        VStack {
            HStack{
                Spacer()
                Text("Horizontal position accuracy limit for an image:")
                Spacer()
            }
            Text("\(setting.hdopThreshold, specifier: "%.03f")m")
            VStack{
                Slider(value: $setting.hdopThreshold, in: min...max)
            }.onDisappear(perform: {
                camera.showHDOPSettingView = false
            })
        }
        Spacer()
        Spacer()
    }
}
