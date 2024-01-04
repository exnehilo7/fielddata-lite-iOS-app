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
    
    // For allowing Core Data managed object context on the next view
    let persistenceController = PersistenceController.shared
    
    // For add-a-trip popup
    @State private var showingTripNameAlert = false
    @State private var showingDeleteTripAlert = false
    @State private var name = ""
    
    @Environment(\.managedObjectContext) private var viewContext

    // Try my own fetch request and data
    @FetchRequest(sortDescriptors: []) private var trips: FetchedResults<Trip>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(trips) { item in
                    // Once a trip is marked complete, the user cannot toggle it back nor acces the CameraImageView
                    NavigationLink {
                        if !item.complete {
                            // Go to CameraView with trip name as the title
                            CameraImageView(tripName: item.name!)
                                .navigationTitle("\(item.name!)")
                                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        }
                        else {
                            CompletedTripView(tripName: item.name!)
                                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        } // Go to an upload screen instead?
                    } label: {
                        HStack{
                            if item.complete {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                            if item.uploaded {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.orange)
                            }
                            Text(item.name!)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
                // Notify user that pics and metadata will remain in the trip folder
                .alert("Trip Deleted!", isPresented: $showingDeleteTripAlert) {
                    Button("OK", action: showDeleteTripAlert)
                } message: {
                    Text("""
                         NOTE! If pictures were added to the trip, they will still remain within its folder. The folder can be found in: Files -> On My [Device] -> FERN -> [Unique UUID] -> trips.
                         
                         To undo a delete, the trip can be recreated using its original name.
                         """)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    // Pop up a text field to add a Trip name
                    Button(action: showTripNameAlert) {
                        Label("Add Item", systemImage: "plus")
                    }
                    // Enter trip name alert
                    .alert("Enter a trip name", isPresented: $showingTripNameAlert) {
                        TextField("Trip Name", text: $name).foregroundStyle(.purple) // With a black bckground the text is default white
                        //.textInputAutocapitalization(.never)
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
                }
            }
        }
        name = ""
    }

    private func deleteItems(offsets: IndexSet) {
        // Toggle delete alert
        showingDeleteTripAlert = true
        
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
    
    
    private func showTripNameAlert(){
        showingTripNameAlert.toggle()
    }
    
    private func showDeleteTripAlert(){
        showingDeleteTripAlert.toggle()
    }
    
}
