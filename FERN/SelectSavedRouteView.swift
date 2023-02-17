//
//  SelectSavedRouteView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/5/23.
//

import SwiftUI

struct SelectSavedRouteView: View {
    
    @State private var areaList: [SelectNameModel] = []
    
    // Get html root
    private let htmlRoot = HtmlRootModel().htmlRoot

    
    var body: some View {
        
        VStack {
            NavigationStack {
                List (self.areaList) { (area) in
                    NavigationLink(area.name) {
                        // Pass var to view. Query for route does not need a column or organism name.
                        MapView(areaName: area.name, columnName: "", organismName: "", queryName: "query_get_route_for_app")
                    }
                    .bold()
                }
            }
            // query areas. Call PHP GET
        }.task { await getSavedRoutes()}
    } //end View
    
    func getSavedRoutes() async {
        
        guard let url: URL = URL(string: htmlRoot + "/php/" + "menuLoadSavedRouteView.php") else {
            Swift.print("invalid URL")
            return
        }
        
//        var urlRequest: URLRequest = URLRequest(url: url)
//        urlRequest.httpMethod = "GET"
        
        //        URLSession.shared.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
        //            // check if response is okay
        //            guard let data = data else {
        //                print("invalid response")
        //                return
        //            }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // convert JSON response into class model as an array
            self.areaList = try JSONDecoder().decode([SelectNameModel].self, from: data)
        // Debug catching from https://www.hackingwithswift.com/forums/swiftui/decoding-json-data/3024
        }  catch DecodingError.keyNotFound(let key, let context) {
            Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
        } catch let error as NSError {
            NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
        } catch {
            areaList = []
        }
    } // end getSavedRoutes   //).resume()
}

struct SelectSavedRouteView_Previews: PreviewProvider {
    static var previews: some View {
        SelectSavedRouteView()
    }
}
