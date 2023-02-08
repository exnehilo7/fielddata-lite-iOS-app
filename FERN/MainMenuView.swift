//
//  MainMenuView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationStack{
            List {
                    NavigationLink("Select Area") {
                        SelectAreaView(phpFile: "menuSelectAreaView.php", columnName: "area_name")
                            .navigationTitle("Select Area")
                    }
                    NavigationLink("Select Plot") {
                        SelectAreaView(phpFile: "menuSelectPlotView.php",  columnName: "plot_name")
                            .navigationTitle("Select Plot")
                    }
                    NavigationLink("Load Saved Route") {
                       LoadSavedRouteView()
                            .navigationTitle("Load Saved Route")
                    }
                    NavigationLink("Create Custom Route") {
                        CreateCustomRouteView()
                            .navigationTitle("Create Custom Route")
                    }
                    NavigationLink("Test Map") {
                        MapView(areaName: "Davis", columnName: "area_name", organismName: "Besc-113_")
                            .navigationTitle("Test Map")
                    }
                }.bold()
            }
        }
    }

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
