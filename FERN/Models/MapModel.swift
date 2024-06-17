//
//  MapModel.swift
//  FERN
//
//  Created by Hopp, Dan on 6/17/24.
//

import SwiftUI
import MapKit

// ViewController which contains functions that need to be called from SwiftUI
class MapController: UIViewController {
    
    @Published var mapResults: [TempMapPointModel]?
    @Published var hasMapPointsResults = false
    
    // Annotation tracking
    @Published var currentAnnoItem = 0 // starting index is 0, so the first "next" will be 1
    @State private var totalAnnoItems = 0
    // For annotated Map Point Models
    @Published var annotationItems = [MapAnnotationItem]()
    // Create camera position var
    @Published var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    )
    // For map reloads
    @State private var currentCameraPosition: MapCameraPosition?
    @State private var showAlert = false  // NECESSARY? MOVE TO GPS MVC?
    
    // Alerts
    @State private var article = Article(title: "Device Feed Error", description: "Check the Bluetooth or satellite connection. If both are OK, try killing and restarting the app.") // NECESSARY? MOVE TO GPS MVC?
    
    // View toggles
    @Published var showPopover = false

    
    // The BridgingCoordinator received from the SwiftUI View
    var mapControllerBridgingCoordinator: MapBridgingCoordinator!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set self to the BridgingCoordinator
        mapControllerBridgingCoordinator.mapController = self
    }
    
    
    // Make sure forward and backward cycling will stay within the annotation's item count.
    func cycleAnnotations (forward: Bool, _ offset: Int ){
        
        var offsetColor: Color
        
        // Get current annotation's color
        offsetColor = annotationItems[currentAnnoItem].highlightColor
        
        if forward {
            // offset should be -1
            if currentAnnoItem < totalAnnoItems{
                currentAnnoItem += 1
                highlightMapAnnotation(offset, offsetColor)
            }
        }
        else {
            // offset should be 1
            if currentAnnoItem > 0 {
                currentAnnoItem -= 1
                highlightMapAnnotation(offset, offsetColor)
            }
        }
    }
    
    // Draw attention to selected point. Put previous or next point back to its original state
    func highlightMapAnnotation (_ offset: Int, _ currentColor: Color){
        annotationItems[currentAnnoItem].size = 20
        // If currentAnnoItem is blue, make it light blue. Else make it red
        if annotationItems[currentAnnoItem].highlightColor == Color(red: 0, green: 0, blue: 1) {
            annotationItems[currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
        } else {
            annotationItems[currentAnnoItem].highlightColor = Color(red: 1, green: 0, blue: 0)
        }
        
        annotationItems[currentAnnoItem + offset].size = MapPointSize().size
        // If offsetColor is red, make it grey. Else make it blue
        if annotationItems[currentAnnoItem + offset].highlightColor == Color(red: 1, green: 0, blue: 0) {
            annotationItems[currentAnnoItem + offset].highlightColor = Color(red: 0.5, green: 0.5, blue: 0.5)
        } else {
            annotationItems[currentAnnoItem + offset].highlightColor = Color(red: 0, green: 0, blue: 1)
        }
    }
    
    func resetRouteMarkers(settings: [Settings], mapResults: [TempMapPointModel], phpFile: String, postString: String = "") async {
        // remember current map camera position
        currentCameraPosition = cameraPosition
        hasMapPointsResults = false
        currentAnnoItem = 0
        totalAnnoItems = 0
        annotationItems.removeAll(keepingCapacity: true)
        _ = await getMapPointsFromDatabase(settings: settings, mapResults: mapResults, phpFile: phpFile, postString: postString)
        // move map back to current spot
        cameraPosition = currentCameraPosition!
    }
    
    func refreshMap(settings: [Settings], mapResults: [TempMapPointModel], phpFile: String, postString: String = "") async {
        // remember current map camera position
        currentCameraPosition = cameraPosition
        annotationItems.removeAll(keepingCapacity: true)  // or false?
        _ = await getMapPointsFromDatabase(settings: settings, mapResults: mapResults, phpFile: phpFile, postString: postString)
        // move map back to current spot
        cameraPosition = currentCameraPosition!
    }

    func getMapPointsFromDatabase(settings: [Settings], mapResults: [TempMapPointModel], phpFile: String, postString: String = "") async -> [TempMapPointModel] {
        
        self.mapResults = mapResults
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/\(phpFile)") else {
            Swift.print("invalid URL")
            return self.mapResults!
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        let postData = postString.data(using: .utf8)

        
        if let data = try? await TestGlobalFunction().urlSessionUpload(request: request, postData: postData!) {
                do {
                    self.mapResults = try! decodeTempMapPointModelReturn (mapResults: mapResults, data: data)
                    
                    // dont process if result is empty
                    if !self.mapResults!.isEmpty {
                        
                        totalAnnoItems = (self.mapResults!.count - 1) // adjust for array 0-indexing
                        
                        // Put results in an array
                        for result in self.mapResults! {
                            annotationItems.append(MapAnnotationItem(
                                latitude: Double(result.lat) ?? 0,
                                longitude: Double(result.long) ?? 0,
                                routeID: result.routeID,
                                pointOrder: result.pointOrder,
                                organismName: result.organismName,
                                systemName: "xmark.diamond.fill",
                                highlightColor: Color (
                                    red: Double(result.r) ?? 0,
                                    green: Double(result.g) ?? 0,
                                    blue: Double(result.b) ?? 0
                                )
                            ))
                        }
                        
                        // Set staring regoin to the first point in the list
                        // For 17.0's new MapKit SDK:
                        self.cameraPosition = MapCameraPosition.region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: Double(self.mapResults![0].lat) ?? 0, longitude: Double(self.mapResults![0].long) ?? 0),
                                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                        ))
                        
                        // Toggle next and previous arrows(???)
                        if hasMapPointsResults == false {
                            hasMapPointsResults.toggle()
                        }
                        
                        // Release memory?
                        self.mapResults = [TempMapPointModel]()
                    }
                }
            } else {
                print("MapModel Logger messages to go here")
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

        return self.mapResults!
    }
    
    
    func updatePointColor(settings: [Settings], routeID: String, pointOrder: String, phpFile: String, postString: String = "") async {
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/\(phpFile)") else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        let postData = postString.data(using: .utf8)
                
        if let data = try? await urlSessionUploadNoReturn(request: request, postData: postData!) {
            // Mark currently seleted point as "done"
            annotationItems[currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
        } else {
            print("MapModel Logger messages to go here")
            // Call a function to handle all the below?
            // NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
        }
        
    }
    
    
    // MOVED TO A TEST CLASS FILE. NOTE THAT THE SAME ACTION IS BEING USED IN MenuListModel
    // Get database data from a post
//    func urlSessionUpload (request: URLRequest, postData: Data) async throws -> Data {
//        let (data, _) = try await URLSession.shared.upload(for: request, from: postData, delegate: nil)
//        return data
//    }

    func urlSessionUploadNoReturn (request: URLRequest, postData: Data) async throws {
        let (_, _) = try await URLSession.shared.upload(for: request, from: postData, delegate: nil)
    }
    
    // Decode the returning database data
    func decodeTempMapPointModelReturn (mapResults: [TempMapPointModel], data: Data) throws -> [TempMapPointModel] {
        self.mapResults = mapResults
        
        // Is this necessary?
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dataDecodingStrategy = .deferredToData
        decoder.dateDecodingStrategy = .deferredToDate
        
        self.mapResults = try decoder.decode([TempMapPointModel].self, from: data)
        
        return self.mapResults!
    }
}
