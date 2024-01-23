//
//  CompletedTripView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/2/24.
//
//  19-JAN-2024: Switch to SwiftData

import SwiftUI
import SwiftData

struct CompletedTripView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    @Query var sdTrips: [SDTrip]
    
    // From calling view
    var tripName: String
    
    // Activate UploadImage class
    @ObservedObject var uploadImage = UploadImage()
    
    // For progress bar
//    @State private var uploadProg = 0.0
    
    var body: some View {
        Spacer()
        Text("Trip \(tripName) is complete!")
        Text("")
        Text("The images are stored in:")
        Text("Files -> On My [Device] -> FERN ->")
        Text ("[Unique UUID] -> trips -> \(tripName).")
        Spacer()
        ForEach(sdTrips) { item in // There probably is a better way to get just one specific trip
            // Focus on the relevant trip
            if (item.name == tripName){
                // If no upload, show button
                if (!item.allFilesUploaded) {
                    VStack{
                        ProgressView("File \(uploadImage.totalUploaded) of \(uploadImage.totalFiles) Uploaded", value: Double(uploadImage.totalUploaded), total: Double(uploadImage.totalFiles))
                        Button {
                            // Funciton to upload files. Upload needs to know where it left off if there was an error? Alert user if no signal; don't initiate upload? (Don't show button if no signal?)
                            uploadImage.myFileUploadRequest(tripName: tripName, uploadScriptURL: settings[0].uploadScriptURL, trip: item)
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20))
                                Text("Upload Remaining Trip Files")
                                    .font(.headline)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .padding(.horizontal)
                        }
                    }
                } else {Text("Trip uploaded!")}
            }
        }
        Spacer()
    }
    
}

