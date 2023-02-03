//
//  SearchByNameView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//  Basic PHP query to database from https://adnan-tech.com/get-data-from-api-and-show-in-list-swift-ui-php
//

import SwiftUI

struct SearchByNameView: View {
    
    @State var models: [ResponseModel] = []

    var body: some View {
        // Create VStack
        VStack {
            // now show in list
            // to show in list, model class must be identifiable
            
            List (self.models) { (model) in
                HStack {
                    // they are optional
                    Text(model.id ?? "")
                    Text(model.type ?? "").bold()
                }
            }
            
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
                    self.models = try JSONDecoder().decode([ResponseModel].self, from: data)
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

struct SearchByNameView_Previews: PreviewProvider {
    static var previews: some View {
        SearchByNameView()
    }
}
