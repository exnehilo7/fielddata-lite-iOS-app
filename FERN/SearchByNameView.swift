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
    @State var searchResults: [MapPointModel] = []
//    @StateObject var searchResults = MapPointModel()
    @State var organismName = ""
    let htmlRoot = HtmlRootModel()
    
    var body: some View {
        
//        Text("A name: \(areaName.selectedAreaName)")
        
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
                List (searchResults) { (result) in
                    HStack {
//                        Text(result.siteId ?? 0)
                        Text(result.organismName)
                        Text(result.geoPoint)
                    }
                }
            }
        }
    } //end body
    
    // call PHP POST and get query results. Pass area/plot name, org name
    func getMapPoints (_ areaName: String, _ organismName: String) {
        
        
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

//            print("response = \(String(describing: response))")

//            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            
            do {
                // convert JSON response into class model as an array
                self.searchResults = try JSONDecoder().decode([MapPointModel].self, from: data!)
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
