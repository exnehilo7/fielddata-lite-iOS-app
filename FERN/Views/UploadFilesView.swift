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
    
//    @Environment(\.modelContext) var modelContext
//    @Query var sdTrips: [SDTrip]
    
    // From calling view
    var tripName: String
    var uploadURL: String
    var cesiumURL: String
    @Bindable var upload: FileUploadClass
    @ObservedObject var network = NetworkMonitorClass()
    var mapUILayout: String = "none"
    @State var showUnpluggedBatteryAlert = false
    @State var showNoNetworkAlert = false
    @State var showExpensiveNetworkAlert = false
    @State var showConstrainedNetworkAlert = false
    @State var consoleText = ""
//    var tryUpload = FileUploadActor()
    
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
            if upload.isLoading {
                Text("Upload is currently in progress for \(upload.currentTripUploading).")
            } else {
                Text("Trip \(tripName) is complete!")
                Text("")
                Text("The images are stored in:")
                Text("Files -> On My [Device] -> FERN ->")
                Text ("UUID -> trips -> \(tripName) ->")
                Text("images")
            }
        }.font(.system(size: 15))
    }
    
    var initalTripUploads: some View {
//        ForEach(sdTrips) { item in // (There's probably a better way to get just one specific trip)
//            // Focus on the relevant trip
//            if (item.name == tripName){
                VStack {
                    Spacer()
                    tripDataLocationAndUploadStatus
                    Spacer()
                    // If all files not processed & uploaded, show button and bar
//                    if (!upload.allFilesProcessed || !item.allFilesUploaded) {
                        // If all files not uploaded, show bar
//                        if (!item.allFilesUploaded){
                            // progressViewStyle needs to be defined else the bar will have a spinner above it on view load.
//                            ProgressView("File \(upload.totalUploaded) of \(upload.totalFiles) uploaded", value: Double(upload.totalUploaded), total: Double(upload.totalFiles)).progressViewStyle(.linear)
                    ProgressView("File \(upload.totalUploaded) of \(upload.totalFiles) uploaded", value: Double(upload.totalUploaded), total: Double(upload.totalFiles)).progressViewStyle(.linear)
//                        }
                        // Hide upload button if in progress
                        if (!upload.isLoading) {
                            Button {
//                                Task.detached {
//                                    await upload.resetVars()
//                                    await upload.getLocalFilePaths(tripName: tripName, folderName: "metadata")
//                                    await upload.uploadAndShowError(tripName: tripName, uploadURL: uploadURL)
                                if network.isActive {
                                    uploadImages(fileType: "metadata")
                                } else {showNoNetworkAlert = true}
//                                }
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20))
                                    Text("Upload Metadata CSVs")
                                        .font(.headline)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .padding(.horizontal)
                            }
                            Button {
//                                Task.detached {
//                                    await upload.resetVars()
//                                    await upload.getLocalFilePaths(tripName: tripName, folderName: "scores")
//                                    await upload.uploadAndShowError(tripName: tripName, uploadURL: uploadURL)
                                if network.isActive {
                                    uploadImages(fileType: "scores")
                                } else {showNoNetworkAlert = true}
//                                }
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20))
                                    Text("Upload Scoring CSVs")
                                        .font(.headline)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .padding(.horizontal)
                            }
                            Button {
                                if network.isActive {
                                    switch UIDevice.current.batteryState {
                                    case .unplugged:
                                        showUnpluggedBatteryAlert = true
                                    default:
                                        checkForExpensiveNetwork()
                                    }
                                } else {showNoNetworkAlert = true}
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20))
                                    Text("Upload Images")
                                        .font(.headline)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .padding(.horizontal)
                                // Give user option to view trip in Cesium and/or continue with iage uploads
                            }.alert("Charge Cable Not Connected", isPresented: $showUnpluggedBatteryAlert) {
//                                Link("View trip in CesiumJS", destination: URL(string: cesiumURL + "?jarvisCommand='jarvis show me \(tripName) trip'")!)
                                Button("OK", action: {
//                                    upload.continueImageUpload = true
//                                    Task {
//                                        await startInitalTripUpload(trip: item)
//                                    }
                                    checkForExpensiveNetwork()
                                })
                                Button("Cancel", role: .cancel){showUnpluggedBatteryAlert = false}
                            } message: {
                                HStack {
                                    Text("Continue with upload?")
//                                    Text("It is strongly recommended to be connected to a power cable and Wi-Fi when uploading images.")
//                                    Text("NOTE: The app cannot yet run in the background or when the device is locked.")
                                }
                            }.alert("Device Not Connected to Wi-Fi", isPresented: $showExpensiveNetworkAlert) {
                                Button("OK", action: {
                                    if network.isConstrained {
                                        showExpensiveNetworkAlert = false
                                        showConstrainedNetworkAlert = true
                                    } else {
                                        showExpensiveNetworkAlert = false
                                        uploadImages(fileType: "images")
                                    }
                                })
                                Button("Cancel", role: .cancel){showExpensiveNetworkAlert = false}
                            } message: {HStack {Text("Continue with upload?")}
                            }.alert("Low Data Mode is Active", isPresented: $showConstrainedNetworkAlert) {
                                Button("OK", action: {showConstrainedNetworkAlert = false})
                            } message: { HStack {Text("Low Data Mode can be disabled in iOS settings.")}
                            }.alert("Network is Not Connected to the Device", isPresented: $showNoNetworkAlert) {
                                Button("OK", action: {showNoNetworkAlert = false})
                            } message: { HStack {Text("Is the device connected to Wi-Fi, Cellular, or Ethernet?")}
                            }
                        }
//                    } else {Text("✅ Files uploaded! ✅")}
                    Spacer()
                    uploadFeedback
                }.onAppear() {if !upload.isLoading {upload.resetVars()}}
//            }
//        }
    }
    
    var scoringFilesUpload: some View {
        VStack {
            Spacer()

            if (!upload.isLoading) {
                Button {
                    Task {
                        // Set counters
                        upload.resetVars()
                        await startScoringFilesUpload()
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                        Text("Upload Scoring Files")
                            .font(.headline)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    // Give user option to view trip in Cesium and/or continue with iage uploads
                }
            }
            Spacer()
            uploadFeedback
        }

    }
    
    // MARK: Main body
    var body: some View {
        VStack {
            if mapUILayout == "none" {
                initalTripUploads
            }
            else if mapUILayout == "scoring" {
                scoringFilesUpload
            } else {
                Text("No Map UI layout specified.")
            }
        }.onDisappear(perform: {
            upload.showPopover = false
        })
    } // end body view
    
//    private func startInitalTripUpload(trip: SDTrip) async {
//        print("Starting file upload")
//        // Show bar
//        trip.allFilesUploaded = false
//        
//        await upload.beginFileUpload(tripName: tripName, uploadURL: uploadURL, mapUILayout: mapUILayout)
//        
//        // To make FileUploadClass more universal, the SDTrip function passes were removed from FileUploadClass and func finalizeResults's code was moved to this view.
//        // If all files uploaded, set allFilesUploaded = true
//        if (upload.totalFiles == upload.totalUploaded) {
//            trip.allFilesUploaded = true
//            print("🔵 All files uploaded.")
//            upload.appendToTextEditor(text: "🔵 All files uploaded.")
//        }
//        // If all files processed, set allFilesProcessed = true
//        if (upload.totalFiles == upload.totalProcessed) {
//            upload.allFilesProcessed = true
//        }
//    }
    
    private func uploadImages(fileType: String){
        Task.detached {
            // Set counters
            await upload.resetVars()
//                                    await startInitalTripUpload(trip: item)
            await upload.getLocalFilePaths(tripName: tripName, folderName: fileType)
            await upload.uploadAndShowError(tripName: tripName, uploadURL: uploadURL)
//                                    Task.detached {
//                                        await tryUpload.getLocalFilePaths(tripName: tripName, folderName: "images")
//                                        await tryUpload.uploadAndShowError(uploadURL: uploadURL)
//                                    }
        }
    }
    
    private func checkForExpensiveNetwork(){
        showUnpluggedBatteryAlert = false
        if network.isExpensive {
            showExpensiveNetworkAlert = true
        } else {uploadImages(fileType: "images")}
    }
    
    private func startScoringFilesUpload() async {
        
        // NEEDS TO SWITCH OVER TO .detached TASK METHOD
//        await upload.beginFileUpload(tripName: tripName, uploadURL: uploadURL, mapUILayout: mapUILayout)

    }
    
}
