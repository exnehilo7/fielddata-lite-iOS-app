//
//  SelectNotesView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/10/23.
//

import SwiftUI

struct SelectNotesView: View {
//    @State private var navLinkText = ""
    @State private var notesList: [SelectNoteModel] = []
    @State private var tempvartomakecompilerhappy = false
    var phpFile: String
    @State private var newNote = ""
    @State private var selectedNote = ""
    @State private var showUpdateButton = false

    // Get html root
    let htmlRoot = HtmlRootModel()
    
    var body: some View {
        
        VStack {
            HStack {
                TextField("Add new note. Tap on an existing note to edit it.", text: $selectedNote, onCommit: {
                    // Call function after user is done entering text. Pass env obj prop and TextField text
//                    getMapPoints()
                    showUpdateButton.toggle()
                }).textFieldStyle(.roundedBorder)
                Spacer()
                if showUpdateButton {
                    Button("Update"){
                        // add text from above to table
                    }.buttonStyle(.borderedProminent).padding(.trailing, 30)
                }
            }
            
            NavigationStack {
                List {
                    ForEach(notesList, id: \.self) { note in
                        Text(note.note).onTapGesture {
                            selectedNote = note.note
                            showUpdateButton.toggle()
                        }
                    }
                    .onDelete(perform: {_ in tempvartomakecompilerhappy = true})
                }.toolbar {
                    EditButton()
                }
            }
        // query notes. Call PHP GET
        }.onAppear(perform: {
                // send request to server
            guard let url: URL = URL(string: htmlRoot.htmlRoot + "/php/" + phpFile) else {
                    Swift.print("invalid URL")
                    return
                }
                
                var urlRequest: URLRequest = URLRequest(url: url)
                urlRequest.httpMethod = "GET"
                URLSession.shared.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                    // check if response is okay
                    guard let data = data else {
                        print("invalid response")
                        return
                    }
                    do {
                        // convert JSON response into class model as an array
                        self.notesList = try JSONDecoder().decode([SelectNoteModel].self, from: data)
                    // Debug catching from https://www.hackingwithswift.com/forums/swiftui/decoding-json-data/3024
                    } catch DecodingError.keyNotFound(let key, let context) {
                        Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
                    } catch DecodingError.valueNotFound(let type, let context) {
                        Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
                    } catch DecodingError.typeMismatch(let type, let context) {
                        Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
                    } catch DecodingError.dataCorrupted(let context) {
                        Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
                    } catch let error as NSError {
                        NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
                    }
                }).resume()
            })
        }
    }

struct SelectNotesView_Previews: PreviewProvider {
    static var previews: some View {
        SelectNotesView(phpFile: "menuSelectNotesView.php")
    }
}
