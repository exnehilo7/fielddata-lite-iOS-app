//
//  SelectTripView.swift
//  FERN
//
//  Created by Hopp, Dan on 11/15/23.
//


import SwiftUI
import CoreData

struct SelectTripView: View {
    
    // For add-a-trip popup
    @State private var showingAlert = false
    @State private var name = ""
    
    @Environment(\.managedObjectContext) private var viewContext

    // Try my own fetch request and data
    @FetchRequest(sortDescriptors: []) private var trips: FetchedResults<Trip>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(trips) { item in
                    NavigationLink {
                        // Go to CameraView with trip name as the title?
                        CameraView(tripName: item.name!)
                            .navigationTitle("\(item.name!)")
                    } label: {
                        HStack{
                            if item.complete {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                            Text(item.name!)
                        }.onTapGesture{ // Toggle complete(?)
                            if (item.complete == false) {
                                item.complete = true
                            } else {item.complete = false}
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    // Pop up a text field to add a Trip name
                    Button(action: showAlert) {
                        Label("Add Item", systemImage: "plus")
                    }
                    .alert("Enter a trip name", isPresented: $showingAlert) {
                        TextField("Trip Name", text: $name).foregroundStyle(.purple)
                        //.textInputAutocapitalization(.never) // on black bckground theh text is white
                        Button("OK", action: addItem)
                        Button("Cancel", role: .cancel){name = ""}
                    } message: {
                        Text("The name must be unique.")
                    }
                }
            }
            Text("Select a trip. To mark a trip as complete, tap on its name.").foregroundStyle(.green) // From app example code.
        }
    }

    private func showAlert(){
        showingAlert.toggle()
    }
    
    private func addItem() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 0 {
            withAnimation {
                let newItem = Trip(context: viewContext)
                newItem.name = name
                
                if viewContext.hasChanges{
                    do {
                        try viewContext.save()
                    } catch {
                        let nsError = error as NSError
                        print("private func addItem error \(nsError), \(nsError.userInfo)")
                    }
                    // name = ""
                }
            }
        }
        name = ""
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { trips[$0] }.forEach(viewContext.delete)

            if viewContext.hasChanges{
                do {
                    try viewContext.save()
                } catch {
                    let nsError = error as NSError
                    print("private func deleteItems error \(nsError), \(nsError.userInfo)")
                }
            }
        }
    }
}
