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
    
    init() {
        let menuListCoordinator = MenuListBridgingCoordinator()
        self._menuListBridgingCoordinator = StateObject(wrappedValue: menuListCoordinator)
    }
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    var body: some View {
        NavigationStack{
            List {
                // Don't access others until URLs have been set and HDOP threshold is not 0
                if (settings.count > 0) &&
                    (settings[0].hdopThreshold > 0)
                {
                    // Select Trip Mode (new trip acquisition)
                    NavigationLink {
                        SelectTripView(map: map, gps: gps, camera: camera)
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
                        SelectMapPlatformView(map: map, gps: gps, camera: camera, mapMode: "View Trip", columnName: "", organismName: "", queryName: "query_get_trip_for_apple_map")
                            .environmentObject(menuListBridgingCoordinator)
                            .navigationTitle("Select Platform")
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse").bold(false).foregroundColor(.gray)
                            Text("View a Trip on a Map")
                        }
                    }
                    // Select a saved route
                    NavigationLink {
                        ShowListFromDatabaseView(map: map, gps: gps, camera: camera, mapMode: "Traveling Salesman", columnName: "", organismName: "", queryName: "query_get_route_for_app")
                            .environmentObject(menuListBridgingCoordinator)
                            .navigationTitle("Select Saved Route")
                    } label: {
                        HStack {
                            Image(systemName: "map").bold(false).foregroundColor(.gray)
                            Text("Routes (Traveling Salesman)")
                        }
                    }
                    // Scan photos in folder for text
                    NavigationLink {
                        ScanPhotosInFolderForText()
                            .navigationTitle("Select Trip")
                    } label: {
                        HStack {
                            Image(systemName: "scanner").bold(false).foregroundColor(.gray)
                            Text("Post-trip Image OCR")
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
//                    // Testing
//                    NavigationLink {
//                        RandoTestingView()
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
        
        // Get the bridging connectors going in the parent view
        HStack {
            MenuListViewControllerRepresentable(menuListBridgingCoordinator: menuListBridgingCoordinator)
        }
        Spacer()
        Text("Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Cannot get version #")").font(.footnote)
            // Start GPS feed if not already running
            .onAppear(perform: {
                startGPS()
                // Reset previously snapped pic if view was swiped down before image was saved
                camera.clearCustomData()
                camera.resetCamera()
            })
        
    }
    
    private func startGPS() {
        gps.startGPSFeed(settings: settings)
    }
}
