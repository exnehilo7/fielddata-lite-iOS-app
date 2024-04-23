//
//  MainMenuView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        List {
            Text("Main Menu")
            
            Section("Options") {
                NavigationLink("Search By Name") {
                    SearchByNameView()
                        .navigationTitle("Search By Name")
                }
                
            }
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
