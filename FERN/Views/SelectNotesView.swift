//
//  SelectNotesView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/10/23.
//

import SwiftUI
import SwiftData

struct SelectNotesView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    @State private var notesList: [SelectNoteModel] = []
    var phpFile: String
    @State private var noteId = "0"
    @State private var textFieldNote = ""
    @State private var showUpdateButton = false
    @State private var showCancelButton = false
    @State private var showAddButton = true
    @State private var queryName = "no_DML_query"
    @State private var showDeleteConfirm = false
    @FocusState private var textFieldIsFocused: Bool
    
    var body: some View {
        
        VStack {
            HStack{
                Spacer()
                Button ("Refresh"){
                    Task {
                        await qryNotes()
                    }
                }.padding(.trailing, 100)
            }
            // Add, edit, and delete note buttons and field
            HStack {
                /* If an onCommit action via the keyboard is preferred, add Bools to
                 determine Add or Update action */
                TextField("Add a new note. Tap on an existing note to edit it.", text: $textFieldNote
                ).textFieldStyle(.roundedBorder).focused($textFieldIsFocused)
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
                                textFieldIsFocused = false
                            }
                        }
                    } label: {
                        Text("Add")
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
                                         Button("Delete this note?", role: .destructive) {
                                             queryName = "delete_note"
                                             Task {
                                                 if !textFieldNote.isEmpty {
                                                     await qryNotes()
                                                     toggleUpdateAndClear()
                                                 }
                                             }
                                          }
                    }.buttonStyle(.borderedProminent).padding(.trailing, 20).transition(.scale)
                    
                    Button("Cancel"){
                        // clear out the text field
                        toggleUpdateAndClear()
                    }.buttonStyle(.borderedProminent).padding(.trailing, 5).transition(.scale)
                    
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
                    }.buttonStyle(.borderedProminent).padding(.trailing, 30).transition(.scale)
                }
            }
            
            // List the notes
            NavigationStack {
                List {
                    ForEach(notesList, id: \.self) { note in
                        // HStacks, Spacer, and a Rectangle to be able to press in the empty space as well
                        HStack {
                            HStack {
                                Text(note.note)
                            }
                            Spacer()
                        }.contentShape(Rectangle()).onTapGesture {
                            // Show selected note
                            textFieldNote = note.note
                            noteId = note.id
                            // Toggle add and update buttons
                            // If no Update, show it and the Clear button
                            withAnimation {
                                if !showUpdateButton {
                                    showUpdateButton.toggle()
                                }
                                // If add is showing, hide it
                                if showAddButton {
                                    showAddButton.toggle()
                                }
                            }
                        }
                    }
                }
            }.task {await qryNotes()}
        }
    }
    
    // Process DML and get notes
    private func qryNotes() async {
        
        // get root
//        let htmlRoot = HtmlRootModel().htmlRoot
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/" + phpFile) else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
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
        
        let postData = postString.data(using: .utf8)
            
            do {
                let (data, _) = try await URLSession.shared.upload(for: request, from: postData!, delegate: nil)
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dataDecodingStrategy = .deferredToData
                decoder.dateDecodingStrategy = .deferredToDate
                
                
                // convert JSON response into class model as an array
                self.notesList = try decoder.decode([SelectNoteModel].self, from: data)
                
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
            } catch {
                notesList = []
            }
    }// end qryNotes
    
    // Hide the update & cancel buttons, clear out the text field, hide keyboard
    private func toggleUpdateAndClear() {
        withAnimation {
            showUpdateButton.toggle()
            showCancelButton.toggle()
            textFieldNote = ""
            textFieldIsFocused = false
            showAddButton.toggle()
        }
    }
} // end view


//struct SelectNotesView_Previews: PreviewProvider {
//    static var previews: some View {
//        SelectNotesView(phpFile: "notes.php")
//    }
//}
