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
    @State private var max: Double = 0.4
//    @State private var useStandardGps = false

        var body: some View {

            Spacer()
            HStack {
                Spacer()
                Toggle("Use Standard GPS", isOn: $setting.useStandardGps)
                    .onChange(of: setting.useStandardGps) {
                        if setting.useStandardGps {max = 40.0} else {max = 0.4}
                        setting.hdopThreshold = 0
                    }.onAppear(perform: {
                        if setting.useStandardGps{
                            max = 40.0
                        }
                        else {
                            max = 0.4
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
                Text("\(setting.hdopThreshold, specifier: "%.02f")")
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
