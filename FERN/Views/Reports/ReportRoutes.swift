//
//  ReportRoutes.swift
//  FERN
//
//  Created by Hopp, Dan on 2/13/23.
//

import SwiftUI
import SwiftData

struct ReportRoutes: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    var phpFile: String
    @State private var totalDistances: [RouteTotalDistanceModel] = []
        
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button ("Refresh"){
                    Task {
                        await qryTotalDistanceReport()
                    }
                }.padding(.trailing, 25)
            }
            // Route total distances table
            Table(totalDistances) {
                TableColumn("Route", value: \.routeName)
                TableColumn("Kilometers") { distance in
                    Text(distance.totalDistanceKm)
                }
            }.task { await qryTotalDistanceReport() }
        }
    }
    
    
    // Process DML and get reports
    private func qryTotalDistanceReport() async {
        
        // get root
//        let htmlRoot = HtmlRootModel().htmlRoot
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/" + phpFile) else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "_query_name=report_route_total_distance"
       
        let postData = postString.data(using: .utf8)
            
            do {
                let (data, _) = try await URLSession.shared.upload(for: request, from: postData!, delegate: nil)
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dataDecodingStrategy = .deferredToData
                decoder.dateDecodingStrategy = .deferredToDate
                
                
                // convert JSON response into class model as an array
                self.totalDistances = try decoder.decode([RouteTotalDistanceModel].self, from: data)
                
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
                totalDistances = []
            }
    }// end qryTotalDistanceReport
}

//struct ReportRoutes_Previews: PreviewProvider {
//    static var previews: some View {
//        ReportRoutes(phpFile: "menusAndReports.php")
//    }
//}
