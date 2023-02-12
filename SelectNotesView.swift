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
//    @State private var newNote = ""
    @State private var noteId = "0"
    @State private var textFieldNote = ""
    @State private var showUpdateButton = false
    @State private var showCancelButton = false
    @State private var showAddButton = true
    @State private var queryName = "no_DML_query"
    @State private var showDeleteConfirm = false
    @FocusState private var testFieldIsFocused: Bool

    // Get html root
    let htmlRoot = HtmlRootModel()
    
    var body: some View {
        
        VStack {
            HStack {
                /* If an onCommit action via the keyboard is preferred, use the Bools to
                 determine Add or Update action */
                TextField("Add a new note. Tap on an existing note to edit it.", text: $textFieldNote
//                            // Don't do a default "go"
//                          Binding(
//                            get: {
//                                return textFieldNote ?? ""
//                            },
//                            set: { value in
//                                var newValue = value
//                                if value.contains("\n") {
//                                    newValue = value.replacingOccurrences(of: "\n", with: "")
//                                }
//                                textFieldNote = newValue
//                            }
//                          )
                ).textFieldStyle(.roundedBorder).focused($testFieldIsFocused)
                Spacer()
                if showAddButton {
                    Button{
                        queryName = "add_note"
                        // Add new text table. Need to wrap in Task for async call
                        
                        Task {
                            // If text is not blank!
                            if !textFieldNote.isEmpty {
                                await qryNotes()
                                // clear the textfield
                                textFieldNote = ""
                                // hide the keyboard
                                testFieldIsFocused = false
                            }
                        }
                    } label: {
                        Text("Add")
                    }.buttonStyle(.borderedProminent).padding(.trailing, 30)
                }
                if showUpdateButton {
                    
                    Button("Cancel"){
                        // clear out the text field
                        toggleUpdateAndClear()
                    }.buttonStyle(.borderedProminent).padding(.trailing, 5)
                    
                    Button{
                        queryName = "update_note"
                        Task {
                            // If text is not blank!
                            if !textFieldNote.isEmpty {
                                await qryNotes()
                                toggleUpdateAndClear()
                            }
                        }
                    } label: {
                        Text("Update")
                    }.buttonStyle(.borderedProminent).padding(.trailing, 30)
                    
                }
            }
            HStack {
                Spacer()
                if showUpdateButton {
                    Button("Delete", role: .destructive){
                        showDeleteConfirm = true
                    }.confirmationDialog("Are you sure?",
                                         isPresented: $showDeleteConfirm) {
                                         Button("Delete the note?", role: .destructive) {
                                           //
                                          }
                    }.buttonStyle(.borderedProminent).padding(.trailing, 30)
                }
            }
            
            NavigationStack {
                List {
                    ForEach(notesList, id: \.self) { note in
                        Text(note.note).onTapGesture {
                            // Show selected note
                            textFieldNote = note.note
                            noteId = note.id
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
//                    .onDelete(perform: {_ in
//                        queryName = "delete_note"
//                        Task {
//                            // If text is not blank!
//                            if !textFieldNote.isEmpty {
//                                await qryNotes()
//                            }
//                        }
//
//
//                    })
                }//.toolbar {
//                    EditButton()
//                }
            }.task {await qryNotes()}
            // query notes. Call PHP GET. MOVE TO ITS OWN FUNCTION
        }
    }
    
    // Process DML and get notes
    func qryNotes() async {
        
        // get root
        let htmlRoot = HtmlRootModel()
        
        // pass name of search column to use
        let request = NSMutableURLRequest(url: NSURL(string: htmlRoot.htmlRoot + "/php/" + phpFile)! as URL)
        request.httpMethod = "POST"
        
        var postString = ""
        
        if queryName == "add_note" {
            postString = "_query_name=\(queryName)&_note=\(textFieldNote)"
        }
        else if queryName == "update_note" {
            postString = "_query_name=\(queryName)&_id=\(noteId)&_note=\(textFieldNote)"
        }
        else if queryName == "delete_note" {
            postString = "_query_name=\(queryName)&_id=\(noteId)"
        }
        
        request.httpBody = postString.data (using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
                   data, response, error in

           if error != nil {
               print("error=\(String(describing: error))")
               return
           }
            
            do {

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dataDecodingStrategy = .deferredToData
                decoder.dateDecodingStrategy = .deferredToDate
                
                
                // convert JSON response into class model as an array
                self.notesList = try decoder.decode([SelectNoteModel].self, from: data!)
                
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
        }
        task.resume()
    }// end getMapPoints
    
    // Hide the update & cancel buttons, clear out the text field, hide keyboard
    func toggleUpdateAndClear() {
        showUpdateButton.toggle()
        showCancelButton.toggle()
        textFieldNote = ""
        testFieldIsFocused = false
        showAddButton.toggle()
    }
    
//    func isTextFieldBlank() -> Bool {
//        if textFieldNote.count
//    }
    
}


struct SelectNotesView_Previews: PreviewProvider {
    static var previews: some View {
        SelectNotesView(phpFile: "menuSelectNotesView.php")
    }
}
