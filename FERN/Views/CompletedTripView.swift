//
//  CompletedTripView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/2/24.
//

import SwiftUI

struct CompletedTripView: View {
    
    // From calling view
    var tripName: String
    
    // Activate UploadImage class
    @ObservedObject var uploadImage = UploadImage()
    
    // Get trips from core data
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: []) private var trip: FetchedResults<Trip>
    
    var body: some View {
        Spacer()
        Text("In development").font(.system(size: 30))
        Text("Trip \(tripName) is complete!")
        Text("")
        Text("The images are stored in:")
        Text("Files -> On My [Device] -> FERN ->")
        Text ("[Unique UUID] -> trips -> \(tripName).")
        Spacer()
        ForEach(trip) { item in
            // Focus on the relevant trip
            if (item.name == tripName){
                // If no upload, show button
                if (!item.uploaded) {
                    Button {
                        // Funciton to upload files. Will use another function to loop through files. Upload needs to know where it left off if there was an error. Alert user if no signal; don't initiate upload. (Don't show button if no signal?)
                        uploadImage.myImageUploadRequestTEST(tripName: tripName)
                        // For now, just toggle the Core Data value
//                        item.uploaded = true
                        // Save change
                        if viewContext.hasChanges{
                            do {
                                try viewContext.save()
                            } catch {
                                let nsError = error as NSError
                                print("private func addItem error \(nsError), \(nsError.userInfo)")
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                            Text("Upload Trip")
                                .font(.headline)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                } else {Text("Trip uploaded!")}
            }
        }
        Spacer()
    }
}

