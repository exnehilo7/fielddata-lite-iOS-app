//
//  SelectTripTypeView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/27/24.
//

import SwiftUI
import SwiftData

struct SelectTripTypeView: View {
    
    @EnvironmentObject var menuListBridgingCoordinator: MenuListBridgingCoordinator
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    var upload: FileUploadClass
    var mapMode: String
    var columnName: String
    var organismName: String
    var mapQuery: String
    var measurements: MeasurementsClass

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
                        ShowListFromDatabaseView(map: map, gps: gps, camera: camera, upload: upload, mapMode: mapMode, columnName: columnName, organismName: organismName, mapQuery: mapQuery, tripType: item.name, measurements: measurements)
                            .navigationTitle("Apple Map")
                            .environmentObject(menuListBridgingCoordinator)
                    }
                }
            }
            // query routes. Call PHP GET
        }.task { await getListItems()}
    }
    
    private func getListItems() async {
        
        // Need to reset vars in MapModel
        map.resetMapModelVariables()
        
        await getListOfTripsInDatabase()
        
    }

    private func getListOfTripsInDatabase() async {
        
        self.list = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, nameList: list, phpFile: "menusAndReports.php", isMethodPost: true, postString: "_query_name=trip_type_view")
    }
    
}
