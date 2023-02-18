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
    
    var body: some View {
        
        VStack {
            HStack{
                Spacer()
                Button ("Refresh"){
                    Task {
                        await qryAreas()
                    }
                }.padding(.trailing, 25)
            }
            NavigationStack {
                List (self.areaList) { (area) in
                    NavigationLink(area.name) {
                        // Pass vars to view
                        SearchByNameView(areaName: area.name, columnName: columnName).navigationTitle(area.name)
                    }
                    .bold()
                }
            }
        // Call PHP POST
        }.task {await qryAreas()}
    }
    
    // Process DML and get reports
    private func qryAreas() async {
        
        // get root
        let htmlRoot = HtmlRootModel().htmlRoot
        
//        let request = NSMutableURLRequest(url: NSURL(string: htmlRoot + "/php/" + phpFile)! as URL)
        
        guard let url: URL = URL(string: htmlRoot + "/php/" + phpFile) else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // pass name of search column to use
        let postString = "_query_name=\(columnName)"
       
        
//        request.httpBody = postString.data (using: String.Encoding.utf8)
        let postData = postString.data(using: .utf8)
        
//        let task = URLSession.shared.dataTask(with: request as URLRequest) {
//            data, response, error in
//
//            if error != nil {
//                print("error=\(String(describing: error))")
//                return
//            }
            
            do {
                let (data, _) = try await URLSession.shared.upload(for: request, from: postData!, delegate: nil)
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dataDecodingStrategy = .deferredToData
                decoder.dateDecodingStrategy = .deferredToDate
                
                
                // convert JSON response into class model as an array
                self.areaList = try decoder.decode([SelectNameModel].self, from: data)
                
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
            } catch {
                areaList = []
            }
        //task.resume()
    }// end qryReports
} //end view

struct SelectAreaView_Previews: PreviewProvider {
    static var previews: some View {
        SelectAreaView(phpFile: "menusAndReports.php", columnName: "area_name")
    }
}
