//
//  SearchByNameView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//  Basic PHP query to database from https://adnan-tech.com/get-data-from-api-and-show-in-list-swift-ui-php
//

import SwiftUI

struct SearchByNameView: View {
    
    // Get the env obj from SelectAreaView
    @EnvironmentObject var areaName: AreaName
    @StateObject var searchOrganismName = SearchOrganismName()
    @State private var doesThisWork: [ResponseModel] = []
    @State var organismName = ""
    
    var body: some View {
        // VStack for All
        VStack {
            // HStack for Search field
            HStack {
                // Keep auto correction off
                TextField("Search by Organism Name", text: $organismName, onCommit: {
                    // Call function after user is done entering text. Pass env obj prop and TextField text
                    getMapPoints(areaName.areaName, organismName)
                }).textFieldStyle(.roundedBorder).disableAutocorrection(true)
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
            }
        }
    } //end body
    
    // call PHP post and get query results. Pass area/plot name, org name, name of query to use
    func getMapPoints (_ areaName: String, _ organismName: String) {
        
        // create POST envs
        
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
            
            do {
                // convert JSON response into class model as an array
                self.doesThisWork = try JSONDecoder().decode([ResponseModel].self, from: data)
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
        
    }// end getMapPoints
    
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
}//end View
