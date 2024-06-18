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
    @EnvironmentObject var gpsBridgingCoordinator: GpsBridgingCoordinator
    @EnvironmentObject var mapBridgingCoordinator: MapBridgingCoordinator
    
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
                        /* 14-JUN-2024: Interesting..... The @ObservedObject var clLocationHelper = LocationHelper() in MapQCWithNMEAView is
                         fired twice for every trip that appears in the list? */
                        MapView(mapMode: "trip", tripName: trip.name, columnName: "", organismName: "", queryName: "query_get_trip_for_apple_map")
                            .environmentObject(gpsBridgingCoordinator)
                            .environmentObject(mapBridgingCoordinator)
                    }
                }
            }
            // query DB. Call PHP POST
        }.task { await getTripList()}
        
        
        
    } //end View
    
    private func getTripList() async {
        
        // Need to reset vars in MapModel
        mapBridgingCoordinator.mapController.resetMapModelVariables()
        
        self.tripList = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, nameList: tripList, phpFile: "menusAndReports.php", isMethodPost: true, postString: "_query_name=trips_in_db_view")
    }

}
