//
//  SelectTripForAppleMapView.swift
//  FERN
//
//  Created by Hopp, Dan on 4/29/24.
//
//  14-JUN-2024: Integrated with a MVC

import SwiftUI
import SwiftData

struct SelectTripForAppleMapView: View {
    
    @EnvironmentObject var menuListBridgingCoordinator: MenuListBridgingCoordinator
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    @State private var tripList: [SelectNameModel] = []
    
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
                List (self.tripList) { (trip) in
                    NavigationLink(trip.name) {
                        // Pass var to view. Query for route does not need a column or organism name.
                        MapView(map: map, gps: gps, camera: camera, mapMode: "trip", tripOrRouteName: trip.name, columnName: "", organismName: "", queryName: "query_get_trip_for_apple_map")
                    }
                }
            }
            // query DB. Call PHP POST
        }.task { await getTripList()}
        
        
        
    } //end View
    
    private func getTripList() async {
        
        // Need to reset vars in MapModel
        map.resetMapModelVariables()
        
        self.tripList = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, nameList: tripList, phpFile: "menusAndReports.php", isMethodPost: true, postString: "_query_name=trips_in_db_view")
    }

}
