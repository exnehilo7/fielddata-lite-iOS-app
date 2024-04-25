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
                    // Select a saved route
                    NavigationLink {
                        SelectSavedRouteView()
                            .navigationTitle("Load Saved Route")
                    } label: {
                        HStack {
                            Image(systemName: "map").bold(false).foregroundColor(.gray)
                            Text("Load Saved Route")
                        }
                    }
                    // Search within an area
                    NavigationLink {
                        SelectAreaView(phpFile: "menusAndReports.php", columnName: "area_name")
                            .navigationTitle("Select Area")
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.dashed").bold(false).foregroundColor(.gray)
                            Text("Select Area")
                        }
                    }
                    // Narrowed search within a plot
                    NavigationLink {
                        SelectAreaView(phpFile: "menusAndReports.php",  columnName: "plot_name")
                            .navigationTitle("Select Plot")
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.center.inset.fill").bold(false).foregroundColor(.gray)
                            Text("Select Plot")
                        }
                    }
                    // Various reports
                    NavigationLink {
                        SelectReportView(phpFile: "menusAndReports.php")
                            .navigationTitle("Select Report")
                    } label: {
                        HStack {
                            Image(systemName: "newspaper").bold(false).foregroundColor(.gray)
                            Text("Reports")
                        }
                    }
                    // Basic notes
                    NavigationLink {
                        SelectNotesView(phpFile: "notes.php")
                            .navigationTitle("Notes")
                    } label: {
                        HStack {
                            Image(systemName: "pencil.line").bold(false).foregroundColor(.gray)
                            Text("Notes")
                        }
                    }
                    // Simple view to see NMEA Arrow Gold Data stream
                    //                NavigationLink {
                    //                    NMEADataView()
                    //                        .navigationTitle("GPS Stream")
                    //                } label: {
                    //                    HStack {
                    //                        Image(systemName: "antenna.radiowaves.left.and.right").bold(false).foregroundColor(.gray)
                    //                        Text("GPS Stream")
                    //                    }
                    //                }
                    // Camera using Arrow GPS
                    NavigationLink {
                        SelectTripView()
                            .navigationTitle("GPS Camera")//.environment(\.managedObjectContext, persistenceController.container.viewContext)
                    } label: {
                        HStack {
                            Image(systemName: "camera").bold(false).foregroundColor(.gray)
                            Text("GPS Camera")
                        }
                    }
                    // List of trips in the database
                    NavigationLink {
                        TripsInDBView()
                            .navigationTitle("Trips")
                    } label: {
                        HStack {
                            Image(systemName: "externaldrive").bold(false).foregroundColor(.gray)
                            Text("Trips in Database")
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
                    // Rando Testing
                    NavigationLink {
                        RandoTestingView()
                            .navigationTitle("Rando Testing")
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.app").bold(false).foregroundColor(.gray)
                            Text("Rando Testing")
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
