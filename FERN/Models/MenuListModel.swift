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

    func getTripListFromDatabase(settings: [Settings], areaList: [SelectNameModel], phpFile: String, isMethodPost: Bool, postString: String = "") async -> [SelectNameModel] {
        
        self.areaList = areaList
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/\(phpFile)") else {
            Swift.print("invalid URL")
            return self.areaList!
        }
        
        // will be used later if isMethodPost is true
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
//        let postString = "_query_name=trips_in_db_view"
        let postData = postString.data(using: .utf8)

        
        // Post method
        if isMethodPost {
            if let data = try? await URLSessionUpload().urlSessionUpload(request: request, postData: postData!) {
                do {
                    return try! decodeSelectNameModelReturn (areaList: areaList, data: data)
                }
            } else {
                print("MenuListModel Logger messages to go here")
                // Call a function to handle all the below?
                //        } catch DecodingError.keyNotFound(let key, let context) {
                //            Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
                //        } catch DecodingError.valueNotFound(let type, let context) {
                //            Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
                //        } catch DecodingError.typeMismatch(let type, let context) {
                //            Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
                //        } catch DecodingError.dataCorrupted(let context) {
                //            Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
                //        } catch let error as NSError {
                //            NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
            }
        // Regular 'ol URL data get
        } else {
            if let data = try? await URLSessionData().urlSessionData(url: url) {
                do {
                    return try! decodeSelectNameModelReturn (areaList: areaList, data: data)
                }
            } else {
                print("MenuListModel Logger messages to go here")
            }
        }

        return self.areaList!
    }
    
    // MOVE THESE 2 TO A CLASS FILE?  MapModel uses one as well
    // Get database data from a post
//    func urlSessionUpload (request: URLRequest, postData: Data) async throws -> Data {
//        let (data, _) = try await URLSession.shared.upload(for: request, from: postData, delegate: nil)
//        return data
//    }
//    // Get database data, no post
//    func urlSessionData (url: URL) async throws -> Data {
//        let (data, _) = try await URLSession.shared.data(from: url)
//        return data
//    }
    
    // Decode the returning database data
    func decodeSelectNameModelReturn (areaList: [SelectNameModel], data: Data) throws -> [SelectNameModel] {
        self.areaList = areaList
        self.areaList = try JSONDecoder().decode([SelectNameModel].self, from: data)
        return self.areaList!
    }
}
