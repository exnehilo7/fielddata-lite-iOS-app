//
//  MenuListModel.swift
//  FERN
//
//  Created by Hopp, Dan on 6/14/24.
//

import SwiftUI

// ViewController which contains functions that need to be called from SwiftUI
class MenuListController: UIViewController {
    
    @Published var areaList: [SelectNameModel]?
    
    // The BridgingCoordinator received from the SwiftUI View
    var menuListControllerBridgingCoordinator: MenuListBridgingCoordinator!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set self to the BridgingCoordinator
        menuListControllerBridgingCoordinator.menuListController = self
    }

    func getTripListFromDatabase(settings: [Settings], areaList: [SelectNameModel]) async -> [SelectNameModel] {
        
        self.areaList = areaList
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/" + "menusAndReports.php") else {
            Swift.print("invalid URL")
            return areaList
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
            self.areaList = []
        }

        return self.areaList!
    }
    
}
