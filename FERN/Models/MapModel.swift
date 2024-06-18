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
    
    @Published var mapResults: [TempMapPointModel] = []
    @Published var hasMapPointsResults = false
    
    // Annotation tracking
    @Published var currentAnnoItem = 0 // starting index is 0, so the first "next" will be 1
    @Published var totalAnnoItems = 0
    // For annotated Map Point Models
    @Published var annotationItems = [MapAnnotationItem]()
    // Create camera position var
    @Published var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    )
    // For map reloadings
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
    
    func resetRouteMarkers(settings: [Settings], phpFile: String, postString: String = "") async {
        // remember current map camera position
        currentCameraPosition = cameraPosition
        hasMapPointsResults = false
        currentAnnoItem = 0
        totalAnnoItems = 0
        annotationItems.removeAll(keepingCapacity: true)
        _ = await getMapPointsFromDatabase(annotationItems: annotationItems, settings: settings, phpFile: phpFile, postString: postString)
        // move map back to current spot
        cameraPosition = currentCameraPosition!
    }
    
    func refreshMap(settings: [Settings], phpFile: String, postString: String = "") async {
        // remember current map camera position
        currentCameraPosition = cameraPosition
        annotationItems.removeAll(keepingCapacity: true)  // or false?
        _ = await getMapPointsFromDatabase(annotationItems: annotationItems, settings: settings, phpFile: phpFile, postString: postString)
        // move map back to current spot
        cameraPosition = currentCameraPosition!
    }

    func resetMapModelVariables(){
        currentAnnoItem = 0
        totalAnnoItems = 0
        hasMapPointsResults = false
        annotationItems = [MapAnnotationItem]()
        cameraPosition = MapCameraPosition.region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            )
        )
    }
    
    func getMapPointsFromDatabase(annotationItems: [MapAnnotationItem], settings: [Settings], phpFile: String, postString: String = "") async -> [MapAnnotationItem]
    {
        
        self.annotationItems = annotationItems
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/\(phpFile)") else {
            Swift.print("invalid URL")
            return self.annotationItems //mapResults!
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        let postData = postString.data(using: .utf8)

        
        if let data = try? await URLSessionUpload().urlSessionUpload(request: request, postData: postData!) {

                do {
                    mapResults = try! decodeTempMapPointModelReturn (mapResults: mapResults, data: data)
                    
                    // dont process if result is empty
                    if !mapResults.isEmpty {
                        
                        totalAnnoItems = (mapResults.count - 1) // adjust for array 0-indexing

                        // Put results in an array
                        for result in mapResults {
                            self.annotationItems.append(MapAnnotationItem(
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
                                center: CLLocationCoordinate2D(latitude: Double(mapResults[0].lat) ?? 0, longitude: Double(mapResults[0].long) ?? 0),
                                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                        ))
                        
                        // Toggle next and previous arrows(???)
                        if hasMapPointsResults == false {
                            hasMapPointsResults.toggle()
                        }
                        
                        // Release memory?
                        mapResults = [TempMapPointModel]()
                        
                        return self.annotationItems
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

        return self.annotationItems
    }
    
    
    func updatePointColor(settings: [Settings], routeID: String, pointOrder: String, phpFile: String, postString: String = "") async {
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/\(phpFile)") else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        let postData = postString.data(using: .utf8)
                
        if ((try? await URLSessionUploadNoReturn().urlSessionUploadNoReturn(request: request, postData: postData!)) != nil) {
            // Mark currently seleted point as "done"
            annotationItems[currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
        } else {
            print("MapModel Logger messages to go here")
            // Call a function to handle all the below?
            // NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
        }
        
    }
    
    // Decode the returning database data
    func decodeTempMapPointModelReturn (mapResults: [TempMapPointModel] , data: Data) throws -> [TempMapPointModel]  {

        self.mapResults = mapResults
        
        // Are these strategies necessary?
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dataDecodingStrategy = .deferredToData
        decoder.dateDecodingStrategy = .deferredToDate
        
        self.mapResults = try decoder.decode([TempMapPointModel].self, from: data)
        
        return self.mapResults
        
    }
}
