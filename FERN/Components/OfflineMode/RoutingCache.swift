//
//  RoutingCache.swift
//  FERN
//
//  Created by Hopp, Dan on 10/10/24.
//

import Foundation

@MainActor
@Observable class RoutingCache {
    
//
//    var showProgressBar = false
//    
//    private func refreshCache() async -> Bool {
//        
//        showProgressBar = true
//        
//        guard let dir = DocumentsDirectory.dir else {return false}
//        var filePath: URL
//        var list: [SelectNameModel] = []
//        
//        // Create routing and view trip menu item files
//        // cache folder
//        let path = dir.appendingPathComponent("\(DeviceUUID().deviceUUID)/cache/")
//        
//        //routing menu file
//        filePath = ProcessTextfile.createPath(path: path, fileName: "routing_menu.txt")
//        try? FileManager.default.removeItem(at: filePath)
//        
////        upload.appendToTextEditor(text: "🔃 Refreshing cache for routing maps...")
//        
//        list = await menuListBridgingCoordinator.menuListController.getTripListFromDatabase(settings: settings, nameList: list, phpFile: "menuLoadSavedRouteView.php", isMethodPost: false)
//        for menuItem in list {
//            let data = (menuItem.name + "\n").data(using: String.Encoding.utf8)
//            
//            // Create file if not already exists
//            if FileManager.default.fileExists(atPath: filePath.path) {
//                _ = writeLineToFile(path: filePath, data: data!)
//            } else {
//                _ = createFileAndWriteLine(path: filePath, data: data!)
//            }
//            
//            // Write map data to JSON file
//            await writeMapDataToJSONFile(tripOrRouteName: menuItem.name, columnName: "", organismName: "", queryName: "query_get_route_for_app")
//        }
//        
//        //view trip menu
//        filePath = ProcessTextfile.createPath(path: path, fileName: "view_trip_menu.txt")
//        // TO BE CONTINUED....
//        
//        
////        offlineModeModel.offlineModeIsOn = true
////        hideUntilDone = true
////        tea.appendToTextEditor(text: "🟢 Offline cache is refreshed!")
//        
//        return true
//    }
//    
//    // For menu items
//    private func createFileAndWriteLine(path: URL, data: Data) -> Bool {
//        try? data.write(to: path, options: .atomicWrite)
//        return true
//    }
//    private func writeLineToFile(path: URL, data: Data) -> Bool {
//        if let fileHandle = try? FileHandle(forWritingTo: path) {
//            fileHandle.seekToEndOfFile()
//            fileHandle.write(data)
//            fileHandle.closeFile()
//            return true
//        }
//        return false
//    }
//    
//    // For map data
//    private func writeMapDataToJSONFile(tripOrRouteName: String, columnName: String, organismName: String, queryName: String) async {
//        
//        var mapResults: [TempMapPointModel] = []
//        
//        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let fileURL = documentsDirectory.appendingPathComponent("\(DeviceUUID().deviceUUID)/cache/\(tripOrRouteName).json")
//        
//        let postString = "_column_name=\(columnName)&_column_value=\(tripOrRouteName)&_org_name=\(organismName)&_query_name=\(queryName)"
//        
//        guard let url: URL = URL(string: settings[0].databaseURL + "/php/getMapItemsForApp.php") else {
//            Swift.print("invalid URL")
//            return
//        }
//        
//        var request: URLRequest = URLRequest(url: url)
//        request.httpMethod = "POST"
//        let postData = postString.data(using: .utf8)
//        
//        if let data = try? await URLSessionUpload().urlSessionUpload(request: request, postData: postData!) {
//            
//            do {
//                mapResults = try! map.decodeTempMapPointModelReturn (mapResults: mapResults, data: data)
//                
//                // dont process if result is empty
//                if !mapResults.isEmpty {
//                    
//                    let jsonEncoder = JSONEncoder()
//                    let jsonData = try? jsonEncoder.encode(mapResults)
//                    
//                    try? jsonData?.write(to: fileURL)
//                    
//                    // Release memory?
//                    mapResults = [TempMapPointModel]()
//                    
//                    return
//                }
//            }
//        } else {
//            print("MapModel Logger messages to go here")
//        }
//    }
}
