//
//  MenuListModel.swift
//  FERN
//
//  Created by Hopp, Dan on 6/14/24.
//

import SwiftUI

// ViewController which contains functions that need to be called from SwiftUI
class MenuListController: UIViewController {
    
    @Published var nameList: [SelectNameModel]?
    
    // The BridgingCoordinator received from the SwiftUI View
    var menuListControllerBridgingCoordinator: MenuListBridgingCoordinator!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set self to the BridgingCoordinator
        menuListControllerBridgingCoordinator.menuListController = self
    }

    func getTripListFromDatabase(settings: [Settings], nameList: [SelectNameModel], phpFile: String, isMethodPost: Bool, postString: String = "") async -> [SelectNameModel] {
        
        self.nameList = nameList
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/\(phpFile)") else {
            Swift.print("invalid URL")
            return self.nameList!
        }
        
        // will be used later if isMethodPost is true
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        let postData = postString.data(using: .utf8)

        
        // Post method
        if isMethodPost {
            if let data = try? await URLSessionUpload().urlSessionUpload(request: request, postData: postData!) {
                do {
                    return try! decodeSelectNameModelReturn (nameList: nameList, data: data)
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
                    return try! decodeSelectNameModelReturn (nameList: nameList, data: data)
                }
            } else {
                print("MenuListModel Logger messages to go here")
            }
        }

        return self.nameList!
    }
    
    // Decode the returning database data
    func decodeSelectNameModelReturn (nameList: [SelectNameModel], data: Data) throws -> [SelectNameModel] {
        self.nameList = nameList
        self.nameList = try JSONDecoder().decode([SelectNameModel].self, from: data)
        return self.nameList!
    }
}
