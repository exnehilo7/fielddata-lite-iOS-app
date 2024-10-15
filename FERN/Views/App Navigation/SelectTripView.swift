//
//  SelectTripView.swift
//  FERN
//
//  Created by Hopp, Dan on 11/15/23.
//
// 19-JAN-2024: Edit -> Delete has alert appear and immediately disappear
// 19-JAN-2024: Switch to SwiftData


import SwiftUI
import SwiftData

struct SelectTripView: View {
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    var upload: FileUploadClass
    var measurements: MeasurementsClass
    
    // For add-a-trip popup
    @State private var showingTripNameAlert = false
    @State private var showingDeleteTripAlert = false
    @State private var name = ""
    
    @Environment(\.modelContext) var modelContext
    @Query var sdTrips: [SDTrip]
    @Query var settings: [Settings]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sdTrips) { item in
                    NavigationLink {
                        if !item.isComplete {
                            CameraView(map: map, gps: gps, camera: camera, mapMode: "none", tripOrRouteName: item.name, measurements: measurements).navigationTitle("\(item.name)")
                        }
                        // Go to an upload screen
                        else {
//                            // Try to prevent data race by passing swiftdata values(?)
//                            UploadFilesView(tripName: item.name, uploadURL: settings[0].uploadScriptURL, cesiumURL: settings[0].cesiumURL, upload: upload)
                            
                            // Battery and connectivity popups on UploadFilesView is buggy when a trip is marked complete from CameraView. Since MainMenu already uploads files, skip UploadFilesView and show a simple "Trip complete!" view.
                            TripCompleteView()
                        }
                    } label: {
                        HStack{
                            if item.isComplete {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).onTapGesture{
                                    // Toggle upload complete
                                    if item.isComplete {
                                        item.isComplete.toggle()
                                    }
                                }
                            }
                            if item.allFilesUploaded {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.orange)//.onTapGesture{
//                                    // Toggle all files uploaded
//                                     if item.allFilesUploaded {
//                                         item.allFilesUploaded = false
//                                     }
                                 //}
                            }
                            Text(item.name)
                        }
                    }.onAppear(perform: {
                        // Reset measurement / scoring vars
                        measurements.clearMeasurementVars()
                    })
                }
                .onDelete(perform: deleteTrip)
                // Notify user that pics and metadata will be in the trip folder
                .alert("Trip Deleted!", isPresented: $showingDeleteTripAlert) {
                    Button("OK", action: showDeleteTripAlert)
                } message: {
                    Text("""
                         NOTE! If pictures were added to the trip, they will still remain within its folder. The folder can be found in: Files -> On My [Device] -> FERN -> [Unique UUID] -> trips.
                         
                         To undo a delete, the trip can be recreated using its EXACT case-sensitive original name. 
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
                        TextField("Trip Name", text: $name).foregroundStyle(.purple)
                        Button("OK", action: addItem)
                        Button("Cancel", role: .cancel){name = ""}
                    } message: {
                        Text("The name must be unique, must have only alphanumeric characters (- and _ are allowed), and cannot contain any spaces.")
                    }
                }
            }
            Text("Select a trip. To mark a trip as complete, tap on its name.").foregroundStyle(.green)
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
