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
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    @State private var routeList: [SelectNameModel] = []
    
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
                List (self.routeList) { (route) in
                    NavigationLink(route.name) {
                        // Pass var to view. Query for route does not need a column or organism name.
                        MapView(map: map, gps: gps, camera: camera, mapMode: "route", tripOrRouteName: route.name, columnName: "", organismName: "", queryName: "query_get_route_for_app")
                    }
                    .bold()
                }
            }
            // query routes. Call PHP GET
        }.task { await getTripList()}
    } //end View
    
    private func getTripList() async {
        
        // Need to reset vars in MapModel
        map.resetMapModelVariables()
        
        self.routeList = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, nameList: routeList, phpFile: "menuLoadSavedRouteView.php", isMethodPost: false)
    }
}
