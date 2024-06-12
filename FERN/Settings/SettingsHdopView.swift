//
//  SettingsHdopView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/10/24.
//

import SwiftUI
import SwiftData

struct SettingsHdopView: View {
    
    @Environment(\.modelContext) var modelContext
    
//    @Query var settings: [Settings]
    @Bindable var setting: Settings
    
    
//    @State private var hdop: Double = 0
    @State private var min: Double = 0
    @State private var max: Double = 0.9
//    @State private var useStandardGps = false

        var body: some View {

            Spacer()
            HStack {
                Spacer()
                Toggle("Use Bluetooth Device", isOn: $setting.useBluetoothDevice)
                    .onChange(of: setting.useBluetoothDevice) {
                        if !setting.useBluetoothDevice {max = 40.0} else {max = 0.9}
                        setting.hdopThreshold = 0
                    }.onAppear(perform: {
                        if !setting.useBluetoothDevice{
                            max = 40.0
                        }
                        else {
                            max = 0.9
                        }
                    })
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
                }
            }
            Spacer()
            Spacer()
        }
    
//    func addValue() {
//        // Only add one
//        if settings.count < 1 {
//            modelContext.insert(Settings())
//        }
//    }
}
