//
//  StartScreenView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/9/23.
//

import SwiftUI

struct StartScreenView: View {
    var body: some View {
        List {
            Text("Start Screen")
            
            Section("Display TBD") {
                NavigationLink("Main Menu") {
                    MainMenuView()
                        .navigationTitle("FERN")
                }
            }
        }
    }
}

struct StartScreenView_Previews: PreviewProvider {
    static var previews: some View {
        StartScreenView()
    }
}
