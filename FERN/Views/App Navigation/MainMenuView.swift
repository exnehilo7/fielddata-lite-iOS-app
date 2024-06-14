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
    @StateObject private var gpsBridgingCoordinator: GpsBridgingCoordinator
    @StateObject private var menuListBridgingCoordinator: MenuListBridgingCoordinator
    
    init() {
        let gpsCoordinator = GpsBridgingCoordinator()
        self._gpsBridgingCoordinator = StateObject(wrappedValue: gpsCoordinator)
        let menuListCoordinator = MenuListBridgingCoordinator()
        self._menuListBridgingCoordinator = StateObject(wrappedValue: menuListCoordinator)
    }
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    var body: some View {
        NavigationStack{
            List {
                // Don't access others until URLs have been set
                if (settings.count > 0) &&
                    (settings[0].hdopThreshold > 0)
                {
                    // Select Trip Mode
                    NavigationLink {
                        SelectTripModeView()
                            .navigationTitle("Select Trip Mode")
                    } label: {
                        HStack {
                            Image(systemName: "camera").bold(false).foregroundColor(.gray)
                            Text("Capture a New Trip")
                        }
                    }
                    // QC an Uploaded Trip
                    NavigationLink {
                        QCSelectMapTypeView().environmentObject(menuListBridgingCoordinator)
                            .navigationTitle("Select Trip to QC")
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse").bold(false).foregroundColor(.gray)
                            Text("View a Trip on a Map")
                        }
                    }
                    // Select a saved route
                    NavigationLink {
                        SelectSavedRouteView()
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
                        SettingsView()
                            .navigationTitle("Settings")
                    } label: {
                        HStack {
                            Image(systemName: "gearshape").bold(false).foregroundColor(.gray)
                            Text("Settings")
                        }
                    }
                    // Testing
                    NavigationLink {
                        RandoTestingView().environmentObject(gpsBridgingCoordinator)
                            .navigationTitle("Testing")
                    } label: {
                        HStack {
                            Image(systemName: "testtube.2").bold(false).foregroundColor(.gray)
                            Text("Testing")
                        }
                    }
                }
                else
                {
                    // App settings
                    NavigationLink {
                        SettingsView()
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
            
        }//.preferredColorScheme(.dark)
        
        // Get the bridging connectors going in the parent view?
        HStack {
            GpsViewControllerRepresentable(gpsBridgingCoordinator: gpsBridgingCoordinator)
            MenuListViewControllerRepresentable(menuListBridgingCoordinator: menuListBridgingCoordinator)
        }
        Spacer()
        Text("Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Cannot get version #")").font(.footnote)
            // Start GPS feed if not already running
            .onAppear(perform: {
                startGPS()
            })
        
    }
    
    private func startGPS() {
        gpsBridgingCoordinator.gpsController.startGPSFeed(settings: settings)
    }
}
