//
//  SelectTripView.swift
//  FERN
//
//  Created by Hopp, Dan on 11/15/23.
//
// On clicking a trip name: [API] Failed to create 0x88 image slot (alpha=1 wide=1) (client=0x77d3c009) [0x5 (os/kern) failure]  ??
// 19-JAN-2024: Edit -> Delete has alert appear and immediately disappear
// 19-JAN-2024: Switch to SwiftData


import SwiftUI
import SwiftData

struct SelectTripView: View {
    
    // Bridging coordinator
//    @EnvironmentObject var gpsBridgingCoordinator: GpsBridgingCoordinator
//    @EnvironmentObject var cameraBridgingCoordinator: CameraBridgingCoordinator
//    @EnvironmentObject var mapBridgingCoordinator: MapBridgingCoordinator
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    
    var tripMode:String
    
    // For add-a-trip popup
    @State private var showingTripNameAlert = false
    @State private var showingDeleteTripAlert = false
    @State private var name = ""
    
    @Environment(\.modelContext) var modelContext // swift data
    @Query var sdTrips: [SDTrip]
    @Query var settings: [Settings]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sdTrips) { item in
                    NavigationLink {
                        if !item.isComplete {
                            if (tripMode == "fast") {
                                TripModeFastCameraView(tripName: item.name).navigationTitle("🐇 \(item.name)")//.environmentObject(nmea)
                            }
                            else if (tripMode == "thorough") {
                                CameraView(map: map, gps: gps, camera: camera, mapMode: "none", tripOrRouteName: item.name).navigationTitle("🐢 \(item.name)")
//                                    .environmentObject(gpsBridgingCoordinator)
//                                    .environmentObject(mapBridgingCoordinator)
//                                    .environment(gps)
//                                    .environmentObject(cameraBridgingCoordinator)
                            }
                            else {
                                MessageView(message: "No trip type selected.")
                            }
                        }
                        else {
                            // Try to prevent data race by passing swiftdata values(?)
                            CompletedTripView(tripName: item.name, uploadURL: settings[0].uploadScriptURL, cesiumURL: settings[0].cesiumURL)
                        } // Go to an upload screen instead?
                    } label: {
                        HStack{
                            if item.isComplete {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                            if item.allFilesUploaded {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.orange).onTapGesture{
                                    // Toggle upload complete
                                     if item.allFilesUploaded {
                                         item.allFilesUploaded = false
                                     }
                                 }
                            }
                            Text(item.name)
                        }
                    }
                }
                .onDelete(perform: deleteTrip)
                // Notify user that pics and metadata will remain in the trip folder
                .alert("Trip Deleted!", isPresented: $showingDeleteTripAlert) {
                    Button("OK", action: showDeleteTripAlert)
                } message: {
                    Text("""
                         NOTE! If pictures were added to the trip, they will still remain within its folder. The folder can be found in: Files -> On My [Device] -> FERN -> [Unique UUID] -> trips.
                         
                         To undo a delete, the trip can be recreated using its original name.
                         """)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    // Pop up a text field to add a Trip name
                    Button(action: showTripNameAlert) {
                        Label("Add Item", systemImage: "plus")
                    }
                    // Enter trip name alert
                    .alert("Enter a trip name", isPresented: $showingTripNameAlert) {
                        TextField("Trip Name", text: $name).foregroundStyle(.purple) // With a black bckground the text is default white
                        //.textInputAutocapitalization(.never)
                        Button("OK", action: addItem)
                        Button("Cancel", role: .cancel){name = ""}
                    } message: {
                        Text("The name must be unique, must have only alphanumeric characters (- and _ are allowed), and cannot contain any spaces.")
                    }
                }
            }
            Text("Select a trip. To mark a trip as complete, tap on its name.").foregroundStyle(.green) // From app example code.
        }
    }
    
    private func addItem() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 0 {
            withAnimation {

                // Remove special characters
                let pattern = "[^A-Za-z0-9_-]+"
                name = name.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
                modelContext.insert(SDTrip(name: name, isComplete: false, allFilesUploaded: false, files: []))
            }
        }
        name = ""
    }

    func deleteTrip(_ indexSet: IndexSet) {
        // Toggle delete alert
        showingDeleteTripAlert = true
        for index in indexSet {
            let trip = sdTrips[index]
            modelContext.delete(trip)
        }
    }
    
    
    private func showTripNameAlert(){
        showingTripNameAlert.toggle()
    }
    
    private func showDeleteTripAlert(){
        showingDeleteTripAlert.toggle()
    }
    
}
