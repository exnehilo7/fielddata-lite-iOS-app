//
//  MenuListClass.swift
//  FERN
//
//  Created by Hopp, Dan on 10/11/24.
//

import SwiftUI

class SelectNameClass: Codable, Identifiable {
    var name = ""
}

@MainActor
@Observable class MenuListClass {
    
    var nameList: [SelectNameClass]?
    
    func getTripListFromDatabase(settings: [Settings], nameList: [SelectNameClass], phpFile: String, isMethodPost: Bool, postString: String = "") async -> [SelectNameClass] {
        
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
    func decodeSelectNameModelReturn (nameList: [SelectNameClass], data: Data) throws -> [SelectNameClass] {
        self.nameList = nameList
        self.nameList = try JSONDecoder().decode([SelectNameClass].self, from: data)
        return self.nameList!
    }
}
