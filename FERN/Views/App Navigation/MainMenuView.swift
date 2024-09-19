//
//  MainMenuView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//

import SwiftUI
import SwiftData

struct MainMenuView: View {
    
    // Bridging coordinator
    @StateObject private var menuListBridgingCoordinator: MenuListBridgingCoordinator
    
    @State private var map = MapClass()
    @State private var camera = CameraClass()
    @State private var gps = GpsClass()
    @State private var upload = FileUploadClass()
    @State private var measurements = MeasurementsClass()
    
    init() {
        let menuListCoordinator = MenuListBridgingCoordinator()
        self._menuListBridgingCoordinator = StateObject(wrappedValue: menuListCoordinator)
    }
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    @Query var sdTrips: [SDTrip]
    
    var body: some View {
        
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
                            .navigationTitle("Select Trip Mode")
                    } label: {
                        HStack {
                            Image(systemName: "camera").bold(false).foregroundColor(.gray)
                            Text("Capture a New Trip")
                        }
                    }
                    // QC an Uploaded Trip
                    NavigationLink {
                        SelectMapPlatformView(map: map, gps: gps, camera: camera, upload: upload, mapMode: "View Trip", columnName: "", organismName: "", mapQuery: "query_get_trip_for_apple_map", measurements: measurements)
                            .environmentObject(menuListBridgingCoordinator)
                            .navigationTitle("Select Platform")
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse").bold(false).foregroundColor(.gray)
                            Text("View New Trip")
                        }
                    }
                    // Select a saved route
                    NavigationLink {
                        ShowListFromDatabaseView(map: map, gps: gps, camera: camera, upload: upload, mapMode: "Traveling Salesman", columnName: "", organismName: "", mapQuery: "query_get_route_for_app", tripType: "", measurements: measurements)
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
//                        ScanPhotosInFolderForText()
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
}
