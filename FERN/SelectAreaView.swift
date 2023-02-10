//
//  SelectAreaView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/5/23.
//

import SwiftUI

struct SelectAreaView: View {
    
    @State private var areaList: [SelectNameModel] = []
    var phpFile: String
    var columnName: String

    // Get html root
    let htmlRoot = HtmlRootModel()
    
    var body: some View {
        
        VStack {
            NavigationStack {
                List (self.areaList) { (area) in
                    NavigationLink(area.name) {
                        // Pass vars to view
                        SearchByNameView(areaName: area.name, columnName: columnName).navigationTitle(area.name)
                    }
                    .bold()
                }
                // place areaName in an env obj
            }
        // query areas. Call PHP GET
        }.onAppear(perform: {
                // send request to server
            guard let url: URL = URL(string: htmlRoot.htmlRoot + "/php/" + phpFile) else {
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
                        self.areaList = try JSONDecoder().decode([SelectNameModel].self, from: data)
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

struct SelectAreaView_Previews: PreviewProvider {
    static var previews: some View {
        SelectAreaView(phpFile: "menuSelectAreaView.php", columnName: "area_name")
    }
}
