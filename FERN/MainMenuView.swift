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
                NavigationLink("Load Saved Route") {
                   LoadSavedRouteView()
                        .navigationTitle("Load Saved Route")
                }
                NavigationLink("Select Area") {
                    SelectAreaView(phpFile: "menuSelectAreaView.php", columnName: "area_name")
                        .navigationTitle("Select Area")
                }
                NavigationLink("Select Plot") {
                    SelectAreaView(phpFile: "menuSelectPlotView.php",  columnName: "plot_name")
                        .navigationTitle("Select Plot")
                }
                NavigationLink("Notes") {
                    SelectNotesView(phpFile: "menuSelectNotesView.php")
                        .navigationTitle("Notes")
                }

//                    NavigationLink("Create Custom Route") {
//                        CreateCustomRouteView()
//                            .navigationTitle("Create Custom Route")
//                    }
//                    NavigationLink("Test Map") {
//                        MapView(areaName: "Davis", columnName: "area_name", organismName: "Besc-112",
//                                queryName: "query_search_org_name_by_site")
//                    }
                }.bold()
            }
        }
    }

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
