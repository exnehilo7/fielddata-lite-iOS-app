//
//  MainMenuView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//

import SwiftUI
import SwiftData

struct MainMenuView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    var body: some View {
        NavigationStack{
            List {
                // Don't access others until URLs have been set
                if settings.count > 0 {
                    // Select Trip Mode
                    NavigationLink {
                        SelectTripModeView()
                            .navigationTitle("Select Trip Mode")
                    } label: {
                        HStack {
                            Image(systemName: "camera").bold(false).foregroundColor(.gray)
                            Text("Trips")
                        }
                    }
                    // Select a saved route
                    NavigationLink {
                        SelectSavedRouteView()
                            .navigationTitle("Select Saved Route")
                    } label: {
                        HStack {
                            Image(systemName: "map").bold(false).foregroundColor(.gray)
                            Text("Routes")
                        }
                    }
                    // QC an Uploaded Trip
                    NavigationLink {
                        QCSelectMapTypeView()
                            .navigationTitle("Select Trip to QC")
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.square").bold(false).foregroundColor(.gray)
                            Text("Quality Control Uploaded Trip")
                        }
                    }
                    // Scan photos in folder for text
                    NavigationLink {
                        ScanPhotosInFolderForText()
                            .navigationTitle("Select Trip")
                    } label: {
                        HStack {
                            Image(systemName: "scanner").bold(false).foregroundColor(.gray)
                            Text("Post-trip Image Scanning")
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
                }
                if settings.count < 1 {
                    // App settings
                    NavigationLink {
                        SettingsView()
                            .navigationTitle("Add URLs")
                    } label: {
                        HStack {
                            Image(systemName: "gearshape").bold(false).foregroundColor(.gray)
                            Text("Add URLs")
                        }
                    }
                }
            }.bold().onAppear(perform:{ UIApplication.shared.isIdleTimerDisabled = false})
            }//.preferredColorScheme(.dark)
        Spacer()
        Text("Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Cannot get version #")").font(.footnote)
        }
    }
