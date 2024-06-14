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
                List (self.areaList) { (trip) in
                    NavigationLink(trip.name) {
                        // Pass var to view. Query for route does not need a column or organism name.
                        /* 14-JUN-2024: Interesting..... The @ObservedObject var clLocationHelper = LocationHelper() in the view is
                         fired twice for every trip that appears in the list? */
                        MapQCWithNMEAView(tripName: trip.name, columnName: "", organismName: "", queryName: "query_get_trip_for_apple_map")//.environmentObject(nmea)
                    }
                }
            }
            // query DB. Call PHP POST
        }.task { await getTripList()}
        
        
        
    } //end View
    
    private func getTripList() async {
        self.areaList = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, areaList: areaList, phpFile: "menusAndReports.php", isMethodPost: true, postString: "_query_name=trips_in_db_view")
    }

}
