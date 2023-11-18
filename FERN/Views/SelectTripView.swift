//
//  SelectTripView.swift
//  FERN
//
//  Created by Hopp, Dan on 11/15/23.
//
// On clicking a trip name: [API] Failed to create 0x88 image slot (alpha=1 wide=1) (client=0x77d3c009) [0x5 (os/kern) failure]  ??


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
                        CameraImageView(tripName: item.name!)
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
                        Text("The name must be unique, must have only alphanumeric characters (- and _ are allowed), and cannot contain any spaces.")
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
                // Remove special characters
                let pattern = "[^A-Za-z0-9_-]+"
                name = name.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
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
