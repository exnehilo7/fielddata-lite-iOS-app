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
    @StateObject var searchOrganismName = SearchOrganismName()
    @State var searchResults: [Temp_MapPointModel] = []
    @ObservedObject var test_ObsvObj = Temp_MapPointModel_ObsvObj()
    
    @State var organismName = ""
    let htmlRoot = HtmlRootModel()
    
    @State var hasResults = false
    
    var body: some View {
        
//        var arrayOfObsvObjs = [Temp_MapPointModel_ObsvObj] = []
        
        // VStack for All
        VStack {
            
            // HStack for Search field
            HStack {
                // Keep auto correction off
                TextField("Enter Organism Name", text: $organismName, onCommit: {
                    // Call function after user is done entering text. Pass env obj prop and TextField text
                    getMapPoints(areaName, organismName)//areaName.areaName, organismName)
                }).textFieldStyle(.roundedBorder).disableAutocorrection(true)
            }
            // VStack for Results
            VStack {
                // To the map screen!
                NavigationStack {
                    // Show NavLink only if there's results
                    if hasResults {
                        NavigationLink("Test Observeable Object") {
//                            MapView().navigationTitle("Map")
                            Test_OvsvObj(willItWork: test_ObsvObj).navigationTitle("Test")
                        }
                    }
                    List (searchResults) { (result) in
                        HStack {
                            //Text(result.siteId ?? 0)
                            Text(result.organismName)
                            Text(result.geoPoint)
                            
                            // try placing in an obsv obj?
                            
                        }
                    }
                } // end navstack
            } //end Results Vstack
        }
    } //end body
    
    // call PHP POST and get query results. Pass area/plot name, org name
    func getMapPoints (_ areaName: String, _ organismName: String) {
        
//        do{
//        // try with URLsession extension
//        let url1 = URL(string: htmlRoot.htmlRoot + "/php/searchOrgNameByArea.php")!
//            let user = try await URLSession.shared.decode(Temp_MapPointModel_ObsvObj.self, from: url1)
//            print("Downloaded \(user.geoPoint)")
//        } catch {
//            print("Download error: \(error.localizedDescription)")
//        }
        
        // pass name of search column to use
        let request = NSMutableURLRequest(url: NSURL(string: htmlRoot.htmlRoot + "/php/searchOrgNameByArea.php")! as URL)
        request.httpMethod = "POST"
        let postString = "_column_name=\(columnName)&_column_value=\(areaName)&_org_name=\(organismName)"
        request.httpBody = postString.data (using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
                   data, response, error in

           if error != nil {
               print("error=\(String(describing: error))")
               return
           }

            
            do {
                // ummmm
//                let user = try await URLSession.shared.decode(Temp_MapPointModel_ObsvObj.self, from: data!)
//                print("Downloaded \(user.geoPoint)")
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dataDecodingStrategy = .deferredToData
                decoder.dateDecodingStrategy = .deferredToDate
                
                _ = try decoder.decode([Temp_MapPointModel_ObsvObj].self, from: data!)
                
                
                
                // convert JSON response into class model as an array
                self.searchResults = try decoder.decode([Temp_MapPointModel].self, from: data!)
                
                hasResults.toggle()
                
//                // try obsv obj
//                _ = try JSONDecoder().decode(Temp_MapPointModel_ObsvObj.self, from: data!)
//                // Result: type mismatch for type Dictionary<String, Any> in JSON: Expected to decode Dictionary<String, Any> but found an array instead.
                
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
    
//    // Checkbox style toggle from https://www.hackingwithswift.com/quick-start/swiftui/customizing-toggle-with-togglestyle
//    struct CheckToggleStyle: ToggleStyle {
//        func makeBody(configuration: Configuration) -> some View {
//            Button {
//                configuration.isOn.toggle()
//            } label: {
//                Label {
//                    configuration.label
//                } icon: {
//                    Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
//                        .foregroundColor(configuration.isOn ? .accentColor : .secondary)
//                        .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
//                        .imageScale(.large)
//                }
//            }
//            .buttonStyle(PlainButtonStyle())
//        }
//    }
    
    struct SearchByNameView_Previews: PreviewProvider {
        static var previews: some View {
            SearchByNameView(areaName: "Davis", columnName: "area_name")
        }
    }
}//end View
