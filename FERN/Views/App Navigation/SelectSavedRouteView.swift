//
//  SelectSavedRouteView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/5/23.
//
//  14-JUN-2024: Integrated with a MVC

import SwiftUI
import SwiftData

struct SelectSavedRouteView: View {
    
    @EnvironmentObject var menuListBridgingCoordinator: MenuListBridgingCoordinator
    @EnvironmentObject var gpsBridgingCoordinator: GpsBridgingCoordinator
    @EnvironmentObject var mapBridgingCoordinator: MapBridgingCoordinator
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    @State private var areaList: [SelectNameModel] = []
    
    var body: some View {
        
        VStack {
            HStack{
                Spacer()
                Button ("Refresh"){
                    Task {
                        await getTripList()
                    }
                }.padding(.trailing, 25)
            }
            NavigationStack {
                List (self.areaList) { (area) in
                    NavigationLink(area.name) {
                        // Pass var to view. Query for route does not need a column or organism name.
                        MapView(tripName: area.name, columnName: "", organismName: "", queryName: "query_get_route_for_app")
                            .environmentObject(gpsBridgingCoordinator)
                            .environmentObject(mapBridgingCoordinator)
                    }
                    .bold()
                }
            }
            // query areas. Call PHP GET
        }.task { await getTripList()}
    } //end View
    
    private func getTripList() async {
        self.areaList = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, areaList: areaList, phpFile: "menuLoadSavedRouteView.php", isMethodPost: false)
    }

}
