//
//  SearchByNameView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//  Basic PHP query to database from https://adnan-tech.com/get-data-from-api-and-show-in-list-swift-ui-php
//

import SwiftUI

//struct testStruct: Codable {
//    var wtf: [SearchByNameModel]
//}

//extension EditMode {
//    var title: String {
//        self == .active ? "Done" : "Edit"
//    }
//
//    mutating func toggle() {
//        self = self == .active ? .inactive : .active
//    }
//}

struct SearchByNameView: View {
    

//    @StateObject var models = PlotList() //: [ResponseModel] = []
    @State var isChecked = true
    
    @State var doesThisWork: [ResponseModel] = []

//    @State private var selection = Set<String>() // WILL THIS WORK???
    
//    @Environment(\.editMode) var editMode
//    private var isEditing: Bool {
//
//        if editMode?.wrappedValue.isEditing == true {
//            Swift.print("test print true")
//
//           return true
//         }
//        Swift.print("test print false")
//         return false
//      }
    
//    @State var editMode: EditMode = .inactive
    
//    private var editButton: some View {
//         Button(action: {
//             self.editMode.toggle()
//         }) {
//             Text(self.editMode.title)
//         }
//     }
//
//     private var addDelButton: some View {
//         if editMode == .inactive {
//             return Button(action: addItem) {
//                 Image(systemName: "plus")
//             }
//         } else {
//             return Button(action: deleteItems) {
//                 Image(systemName: "trash")
//             }
//         }
//     }
//
//    private func addItem() {
//        Swift.print("addItem")
//    }
//
//    private func deleteItems() {
//        print("deleteItem")
//    }
    
    var body: some View {
        
        // WILL THIS WORK??
//        NavigationStack {
//            List(models.plotList, id: \.id, selection: $selection) { name in
//                        HStack {
//                            // they are optional
//                            Text(name.id)
//                            Text(name.type ?? "").bold()
//                        }                    }
//                    .navigationTitle("List Selection")
//                    .toolbar {
//                        EditButton()
//                    }
//                }
        
        // VStack for All
        VStack {
            
//            List (self.doesThisWork) { (does) in
//                HStack {
//                    // they are optional
//                    Text(does.id ?? "")
//                    Text(does.type ?? "").bold()
//                }
//            }
            

            // HStack for Search field
            HStack {
                Text("Testing")
            }
            // VStack for Results
            VStack {
                List (self.doesThisWork) { (does) in
                    HStack {
                        // they are optional
                        Text(does.id ?? "")
                        Text(does.type ?? "").bold()
                    }
                }
//                NavigationStack {
//                    List (models.plotList, id: \.id, selection: $selection) { (model) in
//                        //                List {
//                        //                    ForEach(0..<$models.plotList.count) { idx in //0..<models.plotList.count
//                        HStack {
//                            let label = (model.type ?? "")
//                            Text(label)
//                            //                            let label = (models.plotList[idx].type ?? "")
//                            //                        Toggle(label, isOn: $isChecked).bold().toggleStyle(CheckToggleStyle())
//    //                        Text(model.id)
//                            //                            Text(models.plotList[idx].testId)
//
//                        }
//                    }.toolbar {
////                        ToolbarItem(placement: .navigationBarTrailing) {
////                          EditButton()
////                        }
//                        ToolbarItem(placement: .navigationBarLeading) {
//                                           editButton
//                                       }
//                                       ToolbarItem(placement: .navigationBarTrailing) {
//                                           addDelButton
//                                       }
//                      }
////                    .onChange(of: isEditing) { value in
////                        if value == false {
////                            Swift.print("Is toggled")
////                        }
////                }
//                  } //navstack
                
            }
             // query for search result plot groupings
        }.onAppear(perform: {
                // send request to server
                
                guard let url: URL = URL(string: "http://covid-samples01.ornl.gov/fielddata-lite/php/routesTestQuery.php") else {
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
                            
                            // convert JSON response into class model as an array
                            do {
                                self.doesThisWork = try JSONDecoder().decode([ResponseModel].self, from: data)
//                            } catch {
//                                print(error.localizedDescription)
//                            }
//
//                            // Try the Observeable objects:
//                            do {
//                                self.models.plotList = try JSONDecoder().decode([SearchByNameModel].self, from: data)
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
                
                
    // PUZZLEMENT FROM https://www.hackingwithswift.com/forums/swiftui/trying-to-make-a-observable-object-with-an-array-of-codable-objects-to-be-able-to-reference-it-anywhere-in-my-app/6560
//                let request = URLRequest(url:url)
//
//                        URLSession.shared.dataTask(with: request) { data, response, error in
//                            if let data = data {
//                                if let data = Data(base64Encoded: data){
//                                    // ADDED
//                                    do {
//                                                  self.doesThisWork = try JSONDecoder().decode([ResponseModel].self, from: data)
//                                              } catch {
//                                                  print(error.localizedDescription)
//                                              }
//                                    // END ADDED
//                                    if let decodedResponse = try? JSONDecoder().decode(testStruct.self, from: data) {
//                                        // we have good data – go back to the main thread
//                                        DispatchQueue.main.async {
//                                            // update our UI
//                                            self.models.plotList = decodedResponse.wtf
//                                        }
//
//                                        // everything is good, so we can exit
//                                        return
//                                    }
//                                }
//                            }
//
//                            // if we're still here it means there was a problem
//                            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//                        }.resume()
                
                
                
        // FIRST ORIGINAL VANILLA CODE THAT WORKED:
//                var urlRequest: URLRequest = URLRequest(url: url)
//                urlRequest.httpMethod = "GET"
//                URLSession.shared.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
//                    // check if response is okay
//
//                    guard let data = data else {
//                        print("invalid response")
//                        return
//                    }
//
//                    // convert JSON response into class model as an array
//                    do {
//                        self.models.plotList = try JSONDecoder().decode([SearchByNameModel].self, from: data)
//
//                        // Debug catching from https://www.hackingwithswift.com/forums/swiftui/decoding-json-data/3024
//                    } catch DecodingError.keyNotFound(let key, let context) {
//                        Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
//                    } catch DecodingError.valueNotFound(let type, let context) {
//                        Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
//                    } catch DecodingError.typeMismatch(let type, let context) {
//                        Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
//                    } catch DecodingError.dataCorrupted(let context) {
//                        Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
//                    } catch let error as NSError {
//                        NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
//                    }
//
//                }).resume()
            })
        }
    }

//// Structure for list view
//struct PlotListView: View {
//    @Binding var plotList: PlotList
//
//    var body: some View {
//        HStack {
////                            let label = (model.type ?? "")
//            let label = ($plotList.type ?? "")
////                            Toggle(label, isOn: $models.isSelected[idx]).bold().toggleStyle(CheckToggleStyle())
//            // they are optional
//            Text($plotList.testId)
//
//        }
//    }
//}

// Checkbox style toggle from https://www.hackingwithswift.com/quick-start/swiftui/customizing-toggle-with-togglestyle
struct CheckToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                    .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
                    .imageScale(.large)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchByNameView_Previews: PreviewProvider {
    static var previews: some View {
        SearchByNameView()
    }
}
