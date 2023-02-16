//
//  SearchByNameView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//  Basic PHP query to database from https://adnan-tech.com/get-data-from-api-and-show-in-list-swift-ui-php
//

import SwiftUI

/**
  Test DocC
 */
struct SearchByNameView: View {
    
    var areaName: String // THIS is how variables are passed view-to-view. @EnvironmentObject method has issues(?). See https://medium.com/swlh/swiftui-and-the-missing-environment-object-1a4bf8913ba7 for more info.
    var columnName: String
    @State private var organismName = ""
    @State private var hasResults = false
    @State private var resultsCount = 0
    
    @ObservedObject private var searchOrganismName = SearchOrganismName()
    @State private var searchResults: [TempMapPointModel] = []

    
    var body: some View {
        
        // VStack for All
        VStack {
            // HStack for Search field
            HStack {
                TextField("Enter Organism Name", text: $organismName, onCommit: {
                    // Call function after user is done entering text.
                    getMapPoints()
                }).textFieldStyle(.roundedBorder).disableAutocorrection(true) // Keep auto correction off
            }
            // VStack for Results
            VStack {
                // To the map screen!
                NavigationStack {
                    
                    // Show NavLink only if there's less than 100 results
                    if hasResults && (resultsCount < 100){
                        VStack{
                            NavigationLink {
                                MapView(areaName: areaName, columnName: columnName, organismName: organismName,
                                        queryName: "query_search_org_name_by_site")
                            } label: {
                                HStack {
                                    Image(systemName: "globe.americas.fill").bold(false).foregroundColor(.green)
                                    Text("Show On Map")
                                    Image(systemName: "globe.americas.fill").bold(false).foregroundColor(.green)
                                }
                            }.padding(.top, 20)
                        }
                        Text("(Results are in alphabetical order)")
                        
                        Table(searchResults) {
                                                TableColumn("Results", value: \.organismName)
                                            }
                    }
                    
                    
                } // end navstack
            } //end Vstack
        }
    } //end view body
    
    // call PHP POST and get query results. Pass area/plot name, org name
    private func getMapPoints () {
        
        // get root
        let htmlRoot = HtmlRootModel().htmlRoot
        
        let request = NSMutableURLRequest(url: NSURL(string: htmlRoot + "/php/getMapItemsForApp.php")! as URL)
        
        request.httpMethod = "POST"
        
        // pass name of search column to use
        let postString = "_column_name=\(columnName)&_column_value=\(areaName)&_org_name=\(organismName)&_query_name=query_search_org_name_by_site"
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
                self.searchResults = try decoder.decode([TempMapPointModel].self, from: data!)
                
                // dont show link if result is empty
                if !searchResults.isEmpty {
                    // Get # of items
                    resultsCount = searchResults.count
                    if hasResults == false {
                        hasResults.toggle()
                    }
                }
                
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
    
    struct SearchByNameView_Previews: PreviewProvider {
        static var previews: some View {
            SearchByNameView(areaName: "Davis", columnName: "area_name")
        }
    }
}//end View
