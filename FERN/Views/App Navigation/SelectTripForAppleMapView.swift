//
//  SelectTripForAppleMapView.swift
//  FERN
//
//  Created by Hopp, Dan on 4/29/24.
//

import SwiftUI
import SwiftData

struct SelectTripForAppleMapView: View {
    
    @EnvironmentObject var menuListBridgingCoordinator: MenuListBridgingCoordinator
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    @State private var areaList: [SelectNameModel] = []
    
    var body: some View {
        VStack {
            HStack{
                Spacer()
                Button ("Refresh"){
                    Task {
                        await getTripList()
                    }
                }.padding(.trailing, 25)
            }
            NavigationStack {
                List (self.areaList) { (trip) in
                    NavigationLink(trip.name) {
                        // Pass var to view. Query for route does not need a column or organism name.
                        /* 14-JUN-2024: Interesting..... The @ObservedObject var clLocationHelper = LocationHelper() in the view is
                         fired twice for every trip that appears in the list? */
                        MapQCWithNMEAView(tripName: trip.name, columnName: "", organismName: "", queryName: "query_get_trip_for_apple_map")//.environmentObject(nmea)
                    }
                }
            }
            // query DB. Call PHP POST
        }.task { await getTripList()}
        
        
        
    } //end View
    
    private func getTripList() async {
        self.areaList = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, areaList: areaList)
    }
    
//  private func getSavedTrips() async {
//
//        guard let url: URL = URL(string: settings[0].databaseURL + "/php/" + "menusAndReports.php") else {
//            Swift.print("invalid URL")
//            return
//        }
//        
//        var request: URLRequest = URLRequest(url: url)
//        request.httpMethod = "POST"
//        
//        let postString = "_query_name=trips_in_db_view"
//        
//        let postData = postString.data(using: .utf8)
//        
//        do {
//            let (data, _) = try await URLSession.shared.upload(for: request, from: postData!, delegate: nil)
//
//            // convert JSON response into class model as an array
//            self.areaList = try JSONDecoder().decode([SelectNameModel].self, from: data)
//            
//            // Debug catching from https://www.hackingwithswift.com/forums/swiftui/decoding-json-data/3024
//            }  catch DecodingError.keyNotFound(let key, let context) {
//                Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
//            } catch DecodingError.valueNotFound(let type, let context) {
//                Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
//            } catch DecodingError.typeMismatch(let type, let context) {
//                Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
//            } catch DecodingError.dataCorrupted(let context) {
//                Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
//            } catch let error as NSError {
//                NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
//            } catch {
//                areaList = []
//            }
//    }
}
