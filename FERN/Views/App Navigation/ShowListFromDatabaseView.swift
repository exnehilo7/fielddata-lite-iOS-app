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
    
//    @EnvironmentObject var menuListBridgingCoordinator: MenuListBridgingCoordinator
    
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
    var offlineMode: Bool

    var menuListClass = MenuListClass()
    var routingCache = RoutingCache()
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    @State private var list: [SelectNameClass] = []
    @State private var showRouteCacheRefreshWarning = false
    @State private var hideUntilDone = true
    
    // MARK: PROGRESS BAR
    var progressBar: some View {
        VStack {
            Spacer()
            Text("Refreshing cache...")
            ProgressView("File \(routingCache.processedRouteFiles) of \(routingCache.totalRouteFiles) downloaded", value: Double(routingCache.processedRouteFiles), total: Double(routingCache.totalRouteFiles)).progressViewStyle(.linear)

            Spacer()
        }
    }
    
    // MARK: BUTTONS
    var refreshRouteCache: some View {
        HStack {
            Spacer()
                Button ("Refresh Cache"){
                    Task {
                        showRouteCacheRefreshWarning = true
                    }
                }.padding(.trailing, 25)
                    .alert("Refresh Route Cache", isPresented: $showRouteCacheRefreshWarning) {
                        Button("OK", action: {
                            showRouteCacheRefreshWarning = false
                            Task.detached {
                                // Refresh and get. Show progress bar of map files when refreshing.
                                _ = await routingCache.refreshCache(settings: settings, map: map)
                                await getListOfTravelingSalesmanRoutes()
                            }
                        })
                        Button("Cancel", role: .cancel){ showRouteCacheRefreshWarning = false }
                    } message: {HStack {Text("WARNING! All routes will be overwritten. Continue?")}}
        }
    }
    var refreshDatabaseList: some View {
        HStack {
            Spacer()
                Button ("Refresh"){
                    Task {
                        await getListItems()
                    }
                }.padding(.trailing, 25)
        }
    }
    
    // MARK: MAIN VIEW
    var body: some View {
        VStack {
            // If TS, show cutom offline refresh button
            if mapMode == "Traveling Salesman" {
                refreshRouteCache
            } else {
                refreshDatabaseList
            }
            // If refreshing offline cache, show progress. Else show list.
            if routingCache.showProgressBar {
                progressBar
            } else {
                NavigationStack {
                    List (self.list) { (item) in
                        NavigationLink(item.name) {
                            // Pass var to view. Query for route does not need a column or organism name.
                            MapView(map: map, gps: gps, camera: camera, upload: upload, mapMode: mapMode, tripOrRouteName: item.name, columnName: columnName, organismName: organismName, queryName: mapQuery, measurements: measurements, offlineMode: offlineMode)
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
            }
        }.task {
            await getListItems()
        }
    }
    
    private func getListItems() async {
        
        if mapMode == "View Trip" {
            await getListOfTripsInDatabase()
        } else if mapMode == "Traveling Salesman" {
            await getListOfTravelingSalesmanRoutes()
        }
    }
    
    private func getListOfTravelingSalesmanRoutes() async {
        // Clear and repopulate
        list = []
        await getRoutesFromCache()
//        } else {
//            self.list = await menuListClass.getTripListFromDatabase(settings: settings, nameList: list, phpFile: "menuLoadSavedRouteView.php", isMethodPost: false)
    }
    
    private func getListOfTripsInDatabase() async {
        
        self.list = await menuListClass.getTripListFromDatabase(settings: settings, nameList: list, phpFile: "menusAndReports.php", isMethodPost: true, postString: "_query_name=trips_in_db_view&_trip_type=\(self.tripType)")
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
                    self.list.append(SelectNameClass())
                    self.list[i].name = trimmedString
                }
            }
        } catch {
            print("Error decoding data: \(error)")
        }
    }
    
}
