//
//  RandoTestingView.swift
//  FERN
//
//  Created by Hopp, Dan on 4/25/24.
//

import SwiftUI

struct RandoTestingView: View {
    
    @State private var textNotes = ""
    @State private var result = ""
    @State private var scrubbedNotes = ""
    @State private var numofmatches = 0
    @State private var count = 0
    
    var body: some View {
        VStack {
            HStack {
                Text("Notes:")//.foregroundColor(.white)
                TextField("branch count: 42; status: alive;", text: $textNotes
                ).textFieldStyle(.roundedBorder).autocapitalization(.none)
            }
            TextField("",
                      text: $textNotes,
                      prompt: Text("branch count: 42; status: alive;").foregroundColor(.green.opacity(0.75))
            ).textFieldStyle(.roundedBorder).autocapitalization(.none).foregroundColor(.yellow)
            TextField("",
                      text: $textNotes,
                      prompt: Text("branch count: 42; status: alive;").foregroundColor(.green.opacity(0.5))
            ).textFieldStyle(.roundedBorder).autocapitalization(.none).foregroundColor(.yellow)
            Text(result)
            Text(String(numofmatches))
            Text(textNotes)
            Text(String(count))
        }
        Button("Check"){
            // Remove special characters from user data
            var pattern = "[^A-Za-z0-9,.:;\\s_\\-]+"
            textNotes = textNotes.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
//            
//            // remove any text past the final ;
//            pattern = "[A-Za-z0-9\\s]*$"
//            textNotes = textNotes.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
            
            
            // Count # of proper syntax matches
            count = textNotes.utf16.count
            let range = NSRange(location: 0, length: textNotes.utf16.count)
            //            let regex = try! NSRegularExpression(pattern: "(?:[\\s\\d\\w,.]+\\s*:\\s*[\\s\\d\\w,.]+\\s*;\\s*)+")
            let regex = try! NSRegularExpression(pattern: "[\\s\\d\\w,._\\-]+\\s*:\\s*[\\s\\d\\w,._\\-]+\\s*;\\s*")
            numofmatches = regex.numberOfMatches(in: textNotes, range: range)
            
            // Are both ; : more than 0? Are ; : counts equal? Is : = match count?
            let colonCount = textNotes.filter({ $0 == ":"}).count
            let semicolonCount = textNotes.filter({ $0 == ";"}).count
            
            if (
                (
                    (colonCount > 0 && semicolonCount > 0)
                    && colonCount == semicolonCount
                    && colonCount == numofmatches
                    && textNotes.count > 0
                    && numofmatches > 0
                ) || textNotes.count == 0
            ) {result = "Good to go!"}
            else { result = "Invalid text." }
            
        }
    }
}
