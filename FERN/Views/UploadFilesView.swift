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
    var mapUILayout: String = "none"
    
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
    
    var initalTripUploads: some View {
        ForEach(sdTrips) { item in // (There's probably a better way to get just one specific trip)
            // Focus on the relevant trip
            if (item.name == tripName){
                VStack {
                    Spacer()
                    Text("Trip \(tripName) is complete!")
                    Text("")
                    VStack {
                        Text("The images are stored in:")
                        Text("Files -> On My [Device] -> FERN ->")
                        Text ("UUID -> trips -> \(tripName).")
                    }.font(.system(size: 15))
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
                                Task.detached {
                                    upload.resetVars()
                                    await upload.getLocalFilePaths(tripName: tripName, folderName: "metadata")
                                    await upload.uploadAndShowError(uploadURL: uploadURL)
                                }
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
                                Task.detached {
                                    upload.resetVars()
                                    await upload.getLocalFilePaths(tripName: tripName, folderName: "scores")
                                    await upload.uploadAndShowError(uploadURL: uploadURL)
                                }
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
                                Task.detached {
                                    // Set counters
                                    upload.resetVars()
//                                    await startInitalTripUpload(trip: item)
                                    await upload.getLocalFilePaths(tripName: tripName, folderName: "images")
                                    await upload.uploadAndShowError(uploadURL: uploadURL)
//                                    Task.detached {
//                                        await tryUpload.getLocalFilePaths(tripName: tripName, folderName: "images")
//                                        await tryUpload.uploadAndShowError(uploadURL: uploadURL)
//                                    }
                                    
                                }
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
                            }//.alert("Continue with image upload?", isPresented: $upload.showCesiumAndContinueAlert) {
//                                Link("View trip in CesiumJS", destination: URL(string: cesiumURL + "?jarvisCommand='jarvis show me \(tripName) trip'")!)
//                                Button("OK", action: {
//                                    upload.continueImageUpload = true
//                                    Task {
//                                        await startInitalTripUpload(trip: item)
//                                    }
//                                })
//                                Button("Cancel", role: .cancel){upload.isLoading = false}
//                            } message: {
//                                HStack {
//                                    Text("It is strongly recommended to be connected to a power cable and Wi-Fi when uploading images.")
//                                    Text("NOTE: The app cannot yet run in the background or when the device is locked.")
//                                }
//                            }
                        }
//                    } else {Text("✅ Files uploaded! ✅")}
                    Spacer()
                    uploadFeedback
                }.onAppear() {upload.resetVars()}
            }
        }
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
    
    private func startInitalTripUpload(trip: SDTrip) async {
        print("Starting file upload")
        // Show bar
        trip.allFilesUploaded = false
        
        await upload.beginFileUpload(tripName: tripName, uploadURL: uploadURL, mapUILayout: mapUILayout)
        
        // To make FileUploadClass more universal, the SDTrip function passes were removed from FileUploadClass and func finalizeResults's code was moved to this view.
        // If all files uploaded, set allFilesUploaded = true
        if (upload.totalFiles == upload.totalUploaded) {
            trip.allFilesUploaded = true
            print("🔵 All files uploaded.")
            upload.appendToTextEditor(text: "🔵 All files uploaded.")
        }
        // If all files processed, set allFilesProcessed = true
        if (upload.totalFiles == upload.totalProcessed) {
            upload.allFilesProcessed = true
        }
    }
    
    private func startScoringFilesUpload() async {
        
        await upload.beginFileUpload(tripName: tripName, uploadURL: uploadURL, mapUILayout: mapUILayout)

    }
    
}
