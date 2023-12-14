//
//  UploadTripsView.swift
//  FERN
//
//  Created by Hopp, Dan on 11/20/23. Upload Completed trip folders to a server along with .txt and .jpeg.
//
// Have something to input server connection info (the URL to the server. Store in CoreData. If not exists, prompt user to input value). On the server, have a table with a list of known app UUIDs. If no UUID matches, don't run the import queries.

import SwiftUI

var trySound: some View {
    Button(action: {

        let audio = playSound()
        audio.playError()
        
        
    }, label: {
        HStack {
            Image(systemName: "speaker.fill")
                .font(.system(size: 20))//.foregroundColor(.green)
            
            Text("Noise!")
                .font(.headline)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
        .background(Color.orange)
        .foregroundColor(.white)
        .cornerRadius(20)
        .padding(.horizontal)
    })}

struct UploadTripsView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        trySound
    }
}

#Preview {
    UploadTripsView()
}
