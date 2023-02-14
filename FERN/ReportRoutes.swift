//
//  ReportRoutes.swift
//  FERN
//
//  Created by Hopp, Dan on 2/13/23.
//

import SwiftUI

struct ReportRoutes: View {
    
    var phpFile: String
    @State private var totalDistances: [RouteTotalDistanceModel] = []
        
    var body: some View {
        Table(totalDistances) {
            TableColumn("Route", value: \.routeName)
            TableColumn("Kilometers") { distance in
                Text(distance.totalDistanceKm)
            } //, value: \.totalDistanceMeters)
        }.task { await qryTotalDistanceReport() }
    }
    
    // Process DML and get reports
    func qryTotalDistanceReport() async {
        
        // get root
        let htmlRoot = HtmlRootModel()
        
        // pass name of search column to use
        let request = NSMutableURLRequest(url: NSURL(string: htmlRoot.htmlRoot + "/php/" + phpFile)! as URL)
        request.httpMethod = "POST"
        
        let postString = "_query_name=report_route_total_distance"
       
        
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
                self.totalDistances = try decoder.decode([RouteTotalDistanceModel].self, from: data!)
                
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
    }// end qryTotalDistanceReport
}

struct ReportRoutes_Previews: PreviewProvider {
    static var previews: some View {
        ReportRoutes(phpFile: "menusAndReports.php")
    }
}
