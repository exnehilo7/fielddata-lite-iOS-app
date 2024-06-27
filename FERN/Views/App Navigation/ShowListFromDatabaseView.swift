//
//  ShowListFromDatabaseView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/24/24.
//
//  Generic view to show lists from a database table. For starters, show trips and routes.

import SwiftUI
import SwiftData

struct ShowListFromDatabaseView: View {
    
    @EnvironmentObject var menuListBridgingCoordinator: MenuListBridgingCoordinator
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    var mapMode: String
    var columnName: String
    var organismName: String
    var mapQuery: String
    var tripType: String

    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    @State private var list: [SelectNameModel] = []
    
    var body: some View {
        VStack {
            HStack{
                Spacer()
                Button ("Refresh"){
                    Task {
                        await getListItems()
                    }
                }.padding(.trailing, 25)
            }
            NavigationStack {
                List (self.list) { (item) in
                    NavigationLink(item.name) {
                        // Pass var to view. Query for route does not need a column or organism name.
                        SelectMapUILayoutView(map: map, gps: gps, camera: camera, mapMode: mapMode, tripOrRouteName: item.name, columnName: columnName, organismName: organismName, queryName: mapQuery)
                            .navigationTitle("Select UI Layout")
                    }
                }
            }
            // query routes. Call PHP GET
        }.task { await getListItems()}
    }
    
    private func getListItems() async {
        
        if mapMode == "View Trip" {
            await getListOfTripsInDatabase()
        } else if mapMode == "Traveling Salesman" {
            await getListOfTravelingSalesmanRoutes()
        }
    }
    
    private func getListOfTravelingSalesmanRoutes() async {
        
        self.list = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, nameList: list, phpFile: "menuLoadSavedRouteView.php", isMethodPost: false)
    }
    
    private func getListOfTripsInDatabase() async {
        
        self.list = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, nameList: list, phpFile: "menusAndReports.php", isMethodPost: true, postString: "_query_name=trips_in_db_view&_trip_type=\(self.tripType)")
    }
    
}
