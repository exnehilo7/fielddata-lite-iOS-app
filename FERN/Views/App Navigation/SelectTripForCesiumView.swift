//
//  SelectTripForCesiumView.swift
//  FERN
//
//  Created by Hopp, Dan on 4/29/24.
//

import SwiftUI
import SwiftData
import SafariServices

struct SelectTripForCesiumView: View {
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    @State private var areaList: [SelectNameModel] = []
    
    
    var body: some View {
        VStack {
            HStack{
                Spacer()
                Button ("Refresh"){
                    Task {
                        await getSavedTrips()
                    }
                }.padding(.trailing, 25)
            }
            NavigationStack {
                List (self.areaList) { (trip) in
                    Link(trip.name, destination: URL(string: settings[0].cesiumURL + "?jarvisCommand='jarvis show me \(trip.name) trip'")!)
                }
            }
            // query areas. Call PHP GET
        }.task { await getSavedTrips()}
    } //end View
    
    // To have web browser in-app
//    func openSafariInApp(trip: String){
//        if let url = URL(string: "https://fair.ornl.gov/fielddata/code/html/jarvisWorld.html?jarvisCommand='jarvis show me \(trip.name) trip'") {
//                                        let config = SFSafariViewController.Configuration()
//
//                                        let vc = SFSafariViewController(url: url, configuration: config)
//                                        present(vc, animated: true) // not found in scope?
//                                    }
//    }
    
   private func getSavedTrips() async {
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/" + "menusAndReports.php") else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "_query_name=trips_in_db_view"
        
        let postData = postString.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: postData!, delegate: nil)

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
    }
}
