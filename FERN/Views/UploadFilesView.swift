//
//  UploadFilesView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/2/24.
//
//  Upload a completed trip's text and image files to a server.
//
//  19-JAN-2024: Switch to SwiftData
//  15-MAR-2024: Add checksum. Change array of model objects to array of strings.
//  28-JUN-2024: Move code to MV. Break up view components into their own vars to make it easier to have different view layouts.


import SwiftUI
import SwiftData

struct UploadFilesView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var sdTrips: [SDTrip]
    
    // From calling view
    var tripName: String
    var uploadURL: String
    var cesiumURL: String
    @Bindable var upload: FileUploadClass
    @ObservedObject var network = NetworkMonitorClass()
    var mapUILayout: String = "none"
    
    // MARK: Views
    // Get a message from Upload Image
    var responseMessage: some View {
        VStack {
            Text("PHP Response: \(upload.responseString ?? "None")")
        }.font(.system(size: 20))
            .padding()
    }
    
    var uploadFeedback: some View {
        // Give feedback. Allow user to select text, but don't edit
        TextEditor(text: .constant(upload.consoleText))
            .foregroundStyle(.secondary)
            .font(.system(size: 12)).padding(.horizontal)
            .frame(minHeight: 300, maxHeight: 300)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    var tripDataLocationAndUploadStatus: some View {
        VStack {
                Text("")
                Text("The images are stored in:")
                Text("Files -> On My [Device] -> FERN ->")
                Text ("UUID -> trips -> [trip name] ->")
                Text("images")
            if upload.isLoading {
                Text("Upload is currently in progress for \(upload.currentTripUploading).")
            }
        }.font(.system(size: 15))
            .alert("Charge Cable Not Connected", isPresented: $upload.showUnpluggedBatteryAlert) {
                Button("OK", action: {
                    Task.detached {await upload.checkForExpensiveNetwork(sdTrips: sdTrips, uploadURL: uploadURL)}
                })
                Button("Cancel", role: .cancel){upload.showUnpluggedBatteryAlert = false}
            } message: {
                HStack {
                    Text("Continue with upload?")
                }
            }.alert("Device Not Connected to Wi-Fi", isPresented: $upload.showExpensiveNetworkAlert) {
                Button("OK", action: {
                    if network.isConstrained {
                        upload.showExpensiveNetworkAlert = false
                        upload.showConstrainedNetworkAlert = true
                    } else {
                        upload.showExpensiveNetworkAlert = false
                        Task.detached {
                            await upload.loopThroughTripsAndUpload(sdTrips: sdTrips, uploadURL: uploadURL)
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
    
    var initalTripUploads: some View {

        VStack {
            Spacer()
            tripDataLocationAndUploadStatus
            Spacer()

            if upload.isLoading {
                ProgressView("File \(upload.totalUploaded) of \(upload.totalFiles) uploaded", value: Double(upload.totalUploaded), total: Double(upload.totalFiles)).progressViewStyle(.linear)
            }

            Spacer()
            uploadFeedback
        }
    }
    
    // MARK: Main body
    var body: some View {
        VStack {
            initalTripUploads
        }.onDisappear(perform: {
            upload.showPopover = false
        }).onAppear(perform: {
            // Upload any non-uploaded files.
            if !upload.isLoading {
                Task.detached {
                    await upload.checkForUploads(sdTrips: sdTrips, uploadURL: uploadURL)
                }
            }
        })
    } // end body view
}
