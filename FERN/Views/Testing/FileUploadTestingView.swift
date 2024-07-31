//
//  FileUploadTestingView.swift
//  FERN
//
//  Created by Hopp, Dan on 7/30/24.
//

import SwiftUI
import SwiftData

struct FileUploadTestingView: View {

    var tripName: String
    var upload: FileUploadClass
    
    // For add-a-trip popup
    @State private var showingTripNameAlert = false
    @State private var showingDeleteTripAlert = false
    @State private var name = ""
    
    @Environment(\.modelContext) var modelContext // swift data
    @Query var sdTrips: [SDTrip]
    @Query var settings: [Settings]
    
    var body: some View {
        Button(action: {
            let tryUpload = FileUploadActor()
            Task.detached {
                await tryUpload.getLocalFilePaths(tripName: tripName, folderName: "metadata")
//                await tryUpload.beginFileUpload(tripName: tripName, uploadURL: settings[0].uploadScriptURL)
                await tryUpload.uploadAndShowError(uploadURL: settings[0].uploadScriptURL)
            }
        },
        label: {HStack {
            Image(systemName: "doc.text").font(.system(size: 15))
            Text("Upload Image Metadata").font(.system(size: 15))
        }
            .frame(minWidth: 0, maxWidth: 250, minHeight: 0, maxHeight: 30)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        })
        
        Button(action: {
            let tryUpload = FileUploadActor()
            Task.detached {
                await tryUpload.getLocalFilePaths(tripName: tripName, folderName: "scores")
            }
        },
        label: {HStack {
            Image(systemName: "checkmark.square").font(.system(size: 15))
            Text("Upload Scoring Data").font(.system(size: 15))
        }
            .frame(minWidth: 0, maxWidth: 250, minHeight: 0, maxHeight: 30)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        })
        
        Button(action: {
            let tryUpload = FileUploadActor()
            Task.detached {
                await tryUpload.getLocalFilePaths(tripName: tripName, folderName: "images")
//                await tryUpload.beginFileUpload(tripName: tripName, uploadURL: settings[0].uploadScriptURL)
                await tryUpload.uploadAndShowError(uploadURL: settings[0].uploadScriptURL)
            }
        },
        label: {HStack {
            Image(systemName: "photo").font(.system(size: 15))
            Text("Upload Images").font(.system(size: 15))
        }
            .frame(minWidth: 0, maxWidth: 250, minHeight: 0, maxHeight: 30)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        })
    }
}
