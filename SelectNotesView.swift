//
//  SelectNotesView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/10/23.
//
// Quick fix to disable the default action on the Return key from https://stackoverflow.com/questions/72194262/swiftui-texteditor-disable-return-key

import SwiftUI

struct SelectNotesView: View {
//    @State private var navLinkText = ""
    @State private var notesList: [SelectNoteModel] = []
    @State private var tempvartomakecompilerhappy = false
    var phpFile: String
    @State private var newNote = ""
    @State private var selectedNote = ""
    @State private var showUpdateButton = false
    @State private var showCancelButton = false
    @State private var showAddButton = true
    @FocusState private var testFieldIsFocused: Bool

    // Get html root
    let htmlRoot = HtmlRootModel()
    
    var body: some View {
        
        VStack {
            HStack {
                /* If an onCommit action via the keyboard is preferred, use the Bools to
                 determine Add or Update action */
                TextField("Add a new note. Tap on an existing note to edit it.", text:
                    // Don't do a default "go"
                    Binding(
                        get: {
                            return selectedNote
                        },
                        set: { value in
                            var newValue = value
                            if value.contains("\n") {
                                newValue = value.replacingOccurrences(of: "\n", with: "")
                            }
                            selectedNote = newValue
                        }
                    ))
//                onCommit: {
//                    // Call function after user is done entering text. Pass env obj prop and TextField text
////                    getMapPoints()
//
////                    showUpdateButton.toggle()
//                    selectedNote = ""
//                }
                //)
                .textFieldStyle(.roundedBorder).focused($testFieldIsFocused)
                Spacer()
                if showAddButton {
                    Button("Add"){
                        // add new text table. Function will need to be async
                        // if text is not blank!
                        
                        // clear the textfield
                        selectedNote = ""
                        // hide the keyboard
                        testFieldIsFocused = false
                    }.buttonStyle(.borderedProminent).padding(.trailing, 30)
                }
                if showUpdateButton {
                    
                    Button("Cancel"){
                        // clear out the text field
                        toggleUpdateAndClear()
                    }.buttonStyle(.borderedProminent).padding(.trailing, 5)

                    Button("Update"){
                        // update text. async
                        // Make sure it's not blank
                        
                        toggleUpdateAndClear()
                        
                        // Call func to refresh list? How will the list know when to refresh?
                        // Reload page? If so, are toggles needed?
                    }.buttonStyle(.borderedProminent).padding(.trailing, 30)

                }
            }
            
            NavigationStack {
                List {
                    ForEach(notesList, id: \.self) { note in
                        Text(note.note).onTapGesture {
                            // Show selected note
                            selectedNote = note.note
                            // Toggle add and update buttons
                            // If no Update, show it and the Clear button
                            if !showUpdateButton {
                                showUpdateButton.toggle()
                                showCancelButton.toggle()
                            }
                            // If add is showing, hide it
                            if showAddButton {
                                showAddButton.toggle()
                            }
                        }
                    }
                    .onDelete(perform: {_ in tempvartomakecompilerhappy = true})
                }.toolbar {
                    EditButton()
                }
            }
        // query notes. Call PHP GET. MOVE TO ITS OWN FUNCTION
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
    
    // Hide the update & cancel buttons, clear out the text field, hide keyboard
    func toggleUpdateAndClear() {
        showUpdateButton.toggle()
        showCancelButton.toggle()
        selectedNote = ""
        testFieldIsFocused = false
        showAddButton.toggle()
    }
    
    }


struct SelectNotesView_Previews: PreviewProvider {
    static var previews: some View {
        SelectNotesView(phpFile: "menuSelectNotesView.php")
    }
}
