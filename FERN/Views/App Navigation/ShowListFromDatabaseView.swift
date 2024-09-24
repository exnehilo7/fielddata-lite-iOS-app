//
//  ShowListFromDatabaseView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/24/24.
//
//  Generic view to show lists from a database table.

import SwiftUI
import SwiftData

struct ShowListFromDatabaseView: View {
    
    @EnvironmentObject var menuListBridgingCoordinator: MenuListBridgingCoordinator
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    var upload: FileUploadClass
    var mapMode: String
    var columnName: String
    var organismName: String
    var mapQuery: String
    var tripType: String
    var measurements: MeasurementsClass
    var offlineModeModel: OfflineModeModel

    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    @State private var list: [SelectNameModel] = []
    
    var body: some View {
        VStack {
            HStack{
                Spacer()
                if !offlineModeModel.offlineModeIsOn {
                    Button ("Refresh"){
                        Task {
                            await getListItems()
                        }
                    }.padding(.trailing, 25)
                }
            }
            NavigationStack {
                List (self.list) { (item) in
                    NavigationLink(item.name) {                        
                        // Pass var to view. Query for route does not need a column or organism name.
                        MapView(map: map, gps: gps, camera: camera, upload: upload, mapMode: mapMode, tripOrRouteName: item.name, columnName: columnName, organismName: organismName, queryName: mapQuery, measurements: measurements, offlineModeModel: offlineModeModel)
                            .navigationTitle(item.name).font(.subheadline)
                    }
                }
            }.onAppear(perform: {
                // Reset previously snapped pic if view was swiped down before image was saved
                camera.clearCustomData()
                camera.resetCamera()
                
                // Need to reset vars in MapModel
                map.resetMapModelVariables()
                
                // Reset measurement / scoring vars
                measurements.clearMeasurementVars()
            })
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
        // If mode is offline
        if offlineModeModel.offlineModeIsOn {
            await getRoutesFromCache()
        } else {
            self.list = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, nameList: list, phpFile: "menuLoadSavedRouteView.php", isMethodPost: false)
        }
    }
    
    private func getListOfTripsInDatabase() async {
        
        self.list = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, nameList: list, phpFile: "menusAndReports.php", isMethodPost: true, postString: "_query_name=trips_in_db_view&_trip_type=\(self.tripType)")
    }
    
    private func getRoutesFromCache() async {
        do {
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let path = dir.appendingPathComponent("\(DeviceUUID().deviceUUID)/cache/routing_menu.txt")
            // Assuming there'll be one word per line:
            let string = try String(contentsOf: path, encoding: .utf8)
            let wordArray = string.components(separatedBy: CharacterSet.newlines)
            for (i, word) in wordArray.enumerated() {
                let trimmedString = word.trimmingCharacters(in: .whitespaces)
                if trimmedString.count > 0 { // Skip \n-only lines
                    self.list.append(SelectNameModel())
                    self.list[i].name = trimmedString
                }
            }
        } catch {
            print("Error decoding data: \(error)")
        }
    }
    
}
