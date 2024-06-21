//
//  SelectTripForCesiumView.swift
//  FERN
//
//  Created by Hopp, Dan on 4/29/24.
//
//  14-JUN-2024: Integrated with a MVC

import SwiftUI
import SwiftData
import SafariServices

struct SelectTripForCesiumView: View {
    
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
                    Link(trip.name, destination: URL(string: settings[0].cesiumURL + "?jarvisCommand='jarvis show me \(trip.name) trip'")!)
                }
            }
            // query areas. Call PHP GET
        }.task { await getTripList()}
    } //end View
    
    private func getTripList() async {
        self.areaList = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, nameList: areaList, phpFile: "menusAndReports.php", isMethodPost: true, postString: "_query_name=trips_in_db_view")
    }
    
    // To have web browser in-app:
//    func openSafariInApp(trip: String){
//        if let url = URL(string: "https://fair.ornl.gov/fielddata/code/html/jarvisWorld.html?jarvisCommand='jarvis show me \(trip.name) trip'") {
//                                        let config = SFSafariViewController.Configuration()
//
//                                        let vc = SFSafariViewController(url: url, configuration: config)
//                                        present(vc, animated: true) // not found in scope?
//                                    }
//    }
}
