//
//  SearchByNameView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//  Basic PHP query to database from https://adnan-tech.com/get-data-from-api-and-show-in-list-swift-ui-php
//

import SwiftUI

struct SearchByNameView: View {
    

    @StateObject var models = PlotList() //: [ResponseModel] = []
//    @State var isChecked = PlotList(isSelected)


    var body: some View {
        // VStack for All
        VStack {
            // HStack for Search field
            HStack {
                
            }
            // VStack for Results
            VStack {
                // now show in list
                // to show in list, model class must be identifiable
                
//                List (models.plotList, id: \.testId) { (model) in
                List {
                    ForEach(0..<models.plotList.count) { idx in
                        HStack {
//                            let label = (model.type ?? "")
                            let label = (models.plotList[idx].type ?? "")
//                            Toggle(label, isOn: $models.isSelected[idx]).bold().toggleStyle(CheckToggleStyle())
                            // they are optional
                            Text(models.plotList[idx].testId)
                            
                        }
                    }
                }
             // query for search result plot groupings
            }.onAppear(perform: {
                // send request to server
                
                guard let url: URL = URL(string: "http://covid-samples01.ornl.gov/fielddata-lite/php/routesTestQuery.php") else {
                    print("invalid URL")
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
                        self.models.plotList = try JSONDecoder().decode([SearchByNameModel].self, from: data)

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
            })
        }
        
    }
}

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
