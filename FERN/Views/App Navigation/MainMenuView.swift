//
//  MainMenuView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//

import SwiftUI
import SwiftData

// Temp model object for offline mode. To be replaced by a var in persistence's Settings
class OfflineModeModel: Codable, Identifiable {
//    var offlineCacheIsRefreshing = false
    var offlineModeIsOn = false
}

struct MainMenuView: View {
    
    // Bridging coordinator
    @StateObject private var menuListBridgingCoordinator: MenuListBridgingCoordinator
    
    @State private var map = MapClass()
    @State private var camera = CameraClass()
    @State private var gps = GpsClass()
    @State private var upload = FileUploadClass()
    @State private var measurements = MeasurementsClass()
    
    @State private var offlineModeModel = OfflineModeModel()
    @State private var showOfflineModeAlert = false
    @State private var showCacheRefreshWarning = false
    @State private var hideUntilDone = true
    
    init() {
        let menuListCoordinator = MenuListBridgingCoordinator()
        self._menuListBridgingCoordinator = StateObject(wrappedValue: menuListCoordinator)
    }
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    @Query var sdTrips: [SDTrip]
    
    var body: some View {
        if hideUntilDone {
            NavigationStack{
                List {
                    // Don't access others until URLs have been set and HDOP threshold is not 0
                    if (settings.count > 0) &&
                        (settings[0].hdopThreshold > 0)
                    {
                        // Select Trip Mode (new trip acquisition)
                        NavigationLink {
                            SelectTripView(map: map, gps: gps, camera: camera, upload: upload, measurements: measurements)
                                .environment(gps)
                                .navigationTitle("Select or Create a Trip")
                        } label: {
                            HStack {
                                Image(systemName: "camera").bold(false).foregroundColor(.gray)
                                Text("Capture a New Trip")
                            }
                        }
                        // View New Trip on a map
                        NavigationLink {
                            SelectMapPlatformView(map: map, gps: gps, camera: camera, upload: upload, mapMode: "View Trip", columnName: "", organismName: "", mapQuery: "query_get_trip_for_apple_map", measurements: measurements, offlineModeModel: offlineModeModel)
                                .environmentObject(menuListBridgingCoordinator)
                                .navigationTitle("Select Platform")
                        } label: {
                            HStack {
                                Image(systemName: "mappin.and.ellipse").bold(false).foregroundColor(.gray)
                                Text("View Captured Points")
                            }
                        }
                        // Select a saved route
                        NavigationLink {
                            ShowListFromDatabaseView(map: map, gps: gps, camera: camera, upload: upload, mapMode: "Traveling Salesman", columnName: "", organismName: "", mapQuery: "query_get_route_for_app", tripType: "", measurements: measurements, offlineModeModel: offlineModeModel)
                                .environmentObject(menuListBridgingCoordinator)
                                .navigationTitle("Select Saved Route")
                        } label: {
                            HStack {
                                Image(systemName: "map").bold(false).foregroundColor(.gray)
                                Text("Routes")
                            }
                        }
                        // App settings
                        NavigationLink {
                            SettingsView(camera: camera)
                                .navigationTitle("Settings")
                        } label: {
                            HStack {
                                Image(systemName: "gearshape").bold(false).foregroundColor(.gray)
                                Text("Settings")
                            }
                        }
                        //                    // Scan photos in folder for text
                        //                    NavigationLink {
                        //                        ScanPhotosInFolderForText(gps: gps)
                        //                            .navigationTitle("Select Trip")
                        //                    } label: {
                        //                        HStack {
                        //                            Image(systemName: "scanner").bold(false).foregroundColor(.gray)
                        //                            Text("Post-trip Image OCR")
                        //                        }
                        //                    }
                        //                    // Testing
                        //                    NavigationLink {
                        //                        ScoringView()
                        //                            .navigationTitle("Testing")
                        //                    } label: {
                        //                        HStack {
                        //                            Image(systemName: "testtube.2").bold(false).foregroundColor(.gray)
                        //                            Text("Testing")
                        //                        }
                        //                    }
                    }
                    else
                    {
                        // App settings
                        NavigationLink {
                            SettingsView(camera: camera)
                                .navigationTitle("Set Threshold")
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.to.line").bold(false).foregroundColor(.gray)
                                Text("Set Threshold")
                            }
                        }
                    }
                }.bold()
                // No need to toggle device auto-sleep back to on?
                //                .onAppear(perform:{
                //                UIApplication.shared.isIdleTimerDisabled = false
                //                })
                
            }
        }
        
        // Upload feedback
        VStack {
            if upload.isLoading {
                Text("Upload is currently in progress for \(upload.currentTripUploading).").font(.system(size: 15))
            }
            // Give feedback. Allow user to select text, but don't edit
            TextEditor(text: .constant(upload.consoleText))
                .foregroundStyle(.secondary)
                .font(.system(size: 12)).padding(.horizontal)
                .frame(minHeight: 200, maxHeight: 200)
                .fixedSize(horizontal: false, vertical: true)
        }
            
        
    // TEMP ---------------------------------------------------------------------------------------------------------
        VStack {
            if hideUntilDone {
                Spacer()
                //            Text("Cache is refreshing!").bold(true).foregroundColor(.yellow)
                if offlineModeModel.offlineModeIsOn {
                    Text("Offline Mode is ON for the Routing Maps!").bold(true).foregroundColor(.green)
                }
                Button {
                    offlineModeModel.offlineModeIsOn.toggle()
                    showOfflineModeAlert = true
                } label: {
                    Text("Toggle Offline Mode for Routing Map")
                }.buttonStyle(.borderedProminent).tint(.blue)
                    .alert("Offline mode is set to '\(offlineModeModel.offlineModeIsOn)'!", isPresented: $showOfflineModeAlert) {
                        Button("OK", action: {showOfflineModeAlert = false})
                    }
                
                Spacer()
                Button {
                    Task {
                        showCacheRefreshWarning = true
                    }
                } label: {
                    Text("Refresh Offline Cache")
                }.buttonStyle(.borderedProminent).tint(.red)
                    .alert("Cache Refresh", isPresented: $showCacheRefreshWarning) {
                        Button("OK", action: {
                            hideUntilDone = false
                            Task.detached {
                                // Kick off folder refresh. Hide button until complete?
                                _ = await refreshCache()
                            }
                        })
                        Button("Cancel", role: .cancel){showCacheRefreshWarning = false}
                    } message: {HStack {Text("WARNING! Current cache will be overwritten. Continue?")}}
                Spacer()
            }
        }
    // ---------------------------------------------------------------------------------------------------------------
        
        
        // Get the bridging connectors going in the parent view
        HStack {
            MenuListViewControllerRepresentable(menuListBridgingCoordinator: menuListBridgingCoordinator)
        }
        
        Text("Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Cannot get version #")").font(.footnote)
            .onAppear(perform: {
                // Upload any non-uploaded files.
                if !upload.isLoading {
                    Task.detached {
                        await upload.checkForUploads(sdTrips: sdTrips, uploadURL: settings[0].uploadScriptURL)
                    }
                }
                // Start GPS feed if not already running
                startGPS()
                // Reset previously snapped pic if view was swiped down before image was saved
                camera.clearCustomData()
                camera.resetCamera()
            })
            .alert("Charge Cable Not Connected", isPresented: $upload.showUnpluggedBatteryAlert) {
                Button("OK", action: {Task.detached {await upload.checkForExpensiveNetwork(sdTrips: sdTrips, uploadURL: settings[0].uploadScriptURL)}})
                Button("Cancel", role: .cancel){upload.showUnpluggedBatteryAlert = false}
            } message: {HStack {Text("Continue with upload?")}
            }.alert("Device Not Connected to Wi-Fi", isPresented: $upload.showExpensiveNetworkAlert) {
                Button("OK", action: {
                    if upload.network.isConstrained {
                        upload.showExpensiveNetworkAlert = false
                        upload.showConstrainedNetworkAlert = true
                    } else {
                        upload.showExpensiveNetworkAlert = false
                        Task.detached {
                            await upload.loopThroughTripsAndUpload(sdTrips: sdTrips, uploadURL: settings[0].uploadScriptURL)
                        }
                    }
                })
                Button("Cancel", role: .cancel){upload.showExpensiveNetworkAlert = false}
            } message: {HStack {Text("Continue with upload?")}
            }.alert("Low Data Mode is Active", isPresented: $upload.showConstrainedNetworkAlert) {
                Button("OK", action: {upload.showConstrainedNetworkAlert = false})
            } message: { HStack {Text("Low Data Mode can be disabled in iOS settings.")}
            }.alert("Network is Not Connected to the Device", isPresented: $upload.showNoNetworkAlert) {
                Button("OK", action: {upload.showNoNetworkAlert = false})
            } message: { HStack {Text("Is the device connected to Wi-Fi, Cellular, or Ethernet?")}
            }
    }
    
    private func startGPS() {
        gps.startGPSFeed(settings: settings)
    }
    
    // TEMP ---------------------------------------------------------------------------------------------------------
    private func refreshCache() async -> Bool {
        
        guard let dir = DocumentsDirectory.dir else {return false}
        var filePath: URL
        var list: [SelectNameModel] = []
        
        // Create cache folder if not exists
//        let path = dir.appendingPathComponent("\(DeviceUUID().deviceUUID)/cache")
//        filePath = ProcessTextfile.createPath(path: path, fileName: "")
        
        // Delete files in Cache folder
//        do {
//            try FileManager.default.removeItem(at: filePath)
//            print("Successfully deleted files!")
//        } catch {
//            print("Error deleting file: \(error)")
//        }
        
        // Create routing and view trip menu item files
        // cache folder
        let path = dir.appendingPathComponent("\(DeviceUUID().deviceUUID)/cache/")
        
        //routing menu file
        filePath = ProcessTextfile.createPath(path: path, fileName: "routing_menu.txt")
        try? FileManager.default.removeItem(at: filePath)
        
        upload.appendToTextEditor(text: "🔃 Refreshing cache for routing maps...")
        
        list = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, nameList: list, phpFile: "menuLoadSavedRouteView.php", isMethodPost: false)
        for menuItem in list {
            let data = (menuItem.name + "\n").data(using: String.Encoding.utf8)
            
            // Create file if not already exists
            if FileManager.default.fileExists(atPath: filePath.path) {
                _ = writeLineToFile(path: filePath, data: data!)
            } else {
                _ = createFileAndWriteLine(path: filePath, data: data!)
            }
            
            // Write map data to JSON file
            await writeMapDataToJSONFile(tripOrRouteName: menuItem.name, columnName: "", organismName: "", queryName: "query_get_route_for_app")
        }
        
        //view trip menu
        filePath = ProcessTextfile.createPath(path: path, fileName: "view_trip_menu.txt")
        // TO BE CONTINUED....

        
        offlineModeModel.offlineModeIsOn = true
        hideUntilDone = true
        upload.appendToTextEditor(text: "🟢 Offline cache is refreshed!")
        
        return true
    }
    
    // For menu items
    private func createFileAndWriteLine(path: URL, data: Data) -> Bool {
        try? data.write(to: path, options: .atomicWrite)
        return true
    }
    private func writeLineToFile(path: URL, data: Data) -> Bool {
        if let fileHandle = try? FileHandle(forWritingTo: path) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
            return true
        }
        return false
    }

    // For map data
    private func writeMapDataToJSONFile(tripOrRouteName: String, columnName: String, organismName: String, queryName: String) async {
        
        var mapResults: [TempMapPointModel] = []
        
//        guard let dir = DocumentsDirectory.dir else {return}
//        var filePath: URL
//        let path = dir.appendingPathComponent("\(DeviceUUID().deviceUUID)/cache/")
//        filePath = ProcessTextfile.createPath(path: path, fileName: "\(tripOrRouteName).json")
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("\(DeviceUUID().deviceUUID)/cache/\(tripOrRouteName).json")
        
        let postString = "_column_name=\(columnName)&_column_value=\(tripOrRouteName)&_org_name=\(organismName)&_query_name=\(queryName)"
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/getMapItemsForApp.php") else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        let postData = postString.data(using: .utf8)
        
        if let data = try? await URLSessionUpload().urlSessionUpload(request: request, postData: postData!) {

                do {
                    mapResults = try! map.decodeTempMapPointModelReturn (mapResults: mapResults, data: data)
                    
                    // dont process if result is empty
                    if !mapResults.isEmpty {
                        
                        let jsonEncoder = JSONEncoder()
                        let jsonData = try? jsonEncoder.encode(mapResults)
                        
                        try? jsonData?.write(to: fileURL)
                    
                        // Release memory?
                        mapResults = [TempMapPointModel]()
                        
                        return
                    }
                }
            } else {
                print("MapModel Logger messages to go here")
            }
    }
    // --------------------------------------------------------------------------------------------------------------
}
