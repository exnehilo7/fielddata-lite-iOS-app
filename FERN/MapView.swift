//
//  MapView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//  Map basics help from https://www.mongodb.com/developer/products/realm/realm-swiftui-maps-location/

import SwiftUI
import MapKit

/* Within the database funcion, divide general region's zoom level by 125,000 to
 adjust for the table's CesiumJS value.
 The geocoordinates, organism name, and PK from the database are inserted into
 a MapAnnotationItem which each in trun are added to an array. Cycling through
 the array is done by simple inetger variables. (Apparently Swift doesn't have
 .next() and .previous() for arrays?)
 The starting center is the first MapAnnotationItem item. The zoom level is set
 in the getMapPoints function.

 
*/

struct MapView: View {
    
    // From calling view
    var areaName: String
    var columnName: String
    var organismName: String
    var queryName: String
    
    @State var currentAnnoItem = 0 // starting index is 0, so the first "next" will be 1
    @State var totalAnnoItems = 0
    
    // For map points PHP response
    @State var searchResults: [TempMapPointModel] = []
    @State var hasResults = false
    
    // For showing info when a map point is pressed?
    @State private var selectedPoint: MapAnnotationItem?
    
    // For starting region and zooom level PHP response
//    @State var startingRegion: [StartingRegionModel] = []
    
    // To hold Annotated Map Point Models
    @State var annotationItems = [MapAnnotationItem]()
    
    // To hold the starting region's coordinates and zoom level
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    
//    // To hold Annotated starting region
//    @State var regionItem = [RegionAnnotationItem]()
    
    
    // Set hard-coded starting geo loc
    private enum MapDefaults {
        static let latitude = 35.93212
        static let longitude = -84.31022
        static let zoom = 0.05
    }
    
//    var annotationItems = [MapAnnotationItem]
    
    // Make some test points (aka "annotations"). Note that this is using a struct in Models
//    let annotationItems = [
//        MapAnnotationItem(
//            latitude: MapDefaults.latitude,
//            longitude: MapDefaults.longitude),
//        MapAnnotationItem(
//            latitude: 35.931,
//            longitude: -84.31528),
//        MapAnnotationItem(
//            latitude: 35.915,
//            longitude: -84.31728)
//    ]
    
    // Set hard-coded general region at launch.
//    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: MapDefaults.latitude, longitude: MapDefaults.longitude),
//        span: MKCoordinateSpan(latitudeDelta: MapDefaults.zoom, longitudeDelta: MapDefaults.zoom))
    
    
    
    var body: some View {
        
        
        ZStack(alignment: .center) {
            Map(coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: annotationItems
            ) { item in // add points
                // A vanilla point:
//                 MapMarker(coordinate: item.coordinate)
                
                // Use for custom images and colors:
                MapAnnotation(coordinate: item.coordinate, content: {
                    Image(systemName: item.systemName) //leaf.circle
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, .red).font(.system(size: item.size))
                })
            } // end add points
            Text("lat: \(region.center.latitude), long: \(region.center.longitude). Zoom: \(region.span.latitudeDelta)")
                .font(.caption)
                .fontWeight(.semibold)
//                .foregroundColor(.red)
//                .alignByRatio(horizRatio: 0.5, vertRatio: 45)
                .offset(y: -640)
                .padding()
            // Don't display if no results
            if hasResults {
                // Show organism name of the selected point
                Text(annotationItems[currentAnnoItem].organismName).font(.system(size:20)).fontWeight(.bold).offset(y: 520)
                    .onAppear(perform: {
                    // Mark first point on map
                    annotationItems[currentAnnoItem].size = 60
                })
                Button { // arrowshape.backward.fill
                    cycleAnnotations(forward: false)
                    annotationItems[currentAnnoItem].size = 60
                    annotationItems[currentAnnoItem + 1].size = MapPointSize().size
                    print(annotationItems[currentAnnoItem].organismName)
//                    print("current: " + String(currentAnnoItem) + ", ID: " + annotationItems[currentAnnoItem].siteId)
                    
                } label: {
                    Image(systemName: "arrowshape.backward.fill")
                        .font(.system(size: 50))
//                        .foregroundColor(.gray)
                        .grayscale(0.85)
                }.offset(y: 580).offset(x: -75)
        
                Button { // arrowshape.forward.fill
                    cycleAnnotations(forward: true)
                    // Draw attention to selected point
                    annotationItems[currentAnnoItem].size = 60
                    // Put previous' point back to its original state
                    annotationItems[currentAnnoItem - 1].size = MapPointSize().size
                    print(annotationItems[currentAnnoItem].organismName)
//                    print("current: " + String(currentAnnoItem) + ", ID: " + annotationItems[currentAnnoItem].siteId)
                    
                } label: {
                    Image(systemName: "arrowshape.forward.fill")
                        .font(.system(size: 50))
//                        .foregroundColor(.gray)
                        .grayscale(0.85)
                }.offset(y: 580).offset(x: 75)
                
                // Button images demo:
//                Button {
//                    // Test to make sure points remain in order:
//                    for item in annotationItems {
//                        print(item)
//                    }
//                } label: {
//                    Image(systemName: "info.circle.fill")
//                        .font(.system(size: 60))
//                        .grayscale(0.95)
//                }
//                .offset(y: 600)
                
            }
            // For async acticity, use .task instead of .onAppear
        }.task { await getMapPoints()}//.task { await getRegion()}
    }
    
    
    // Make sure forward and backward cycling will stay within the annotation's item count
    func cycleAnnotations (forward: Bool ){
        
        if forward {
            if currentAnnoItem < totalAnnoItems{
                currentAnnoItem += 1
//                print("after increase: " + String(currentAnnoItem))
            }
        }
        else {
            if currentAnnoItem > 0 {
                currentAnnoItem -= 1
//                print("after decrease: " + String(currentAnnoItem))
            }
        }
    }
    
    func getMapPoints () async {
        
        // get root
        let htmlRoot = HtmlRootModel()
        
        // pass name of search column to use
        let request = NSMutableURLRequest(url: NSURL(string: htmlRoot.htmlRoot + "/php/getMapItemsForApp.php")! as URL)
        request.httpMethod = "POST"
        var postString = ""
        // Set pass variables
        if columnName != "" {
            postString = "_column_value=\(areaName)&_query_name=\(queryName)"
        }
        else {
            postString = "_column_name=\(columnName)&_column_value=\(areaName)&_org_name=\(organismName)&_query_name=\(queryName)"
        }
        
        request.httpBody = postString.data (using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                print("error=\(String(describing: error))")
                return
            }
            
            do {
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dataDecodingStrategy = .deferredToData
                decoder.dateDecodingStrategy = .deferredToDate
                
                // Get list of points
                self.searchResults = try decoder.decode([TempMapPointModel].self, from: data!)
                
                // dont insert if result is empty
                if !searchResults.isEmpty {
                    
                    totalAnnoItems = (searchResults.count - 1) // adjust for array 0-indexing
                    
                    // Don't show items if no data
                    if hasResults == false {
                        hasResults.toggle()
                    }
                    
                    // Put results in an array
                    for result in searchResults {
                        annotationItems.append(MapAnnotationItem(
                            latitude: Double(result.lat) ?? 0,
                            longitude: Double(result.long) ?? 0,
                            siteId: result.siteId,
                            organismName: result.organismName,
                            systemName: "tree.circle"
                            ))
                    }
                    // Set staring regoin to the first point in the list
                    self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: Double(searchResults[0].lat) ?? 0, longitude: Double(searchResults[0].long) ?? 0),
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                }
                
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
            }
        }
        task.resume()
    }// end getMapPoints
    
//    func getRegion () async {
//
//        // get root
//        let htmlRoot = HtmlRootModel()
//
//        // pass name of search column to use
//        let request = NSMutableURLRequest(url: NSURL(string: htmlRoot.htmlRoot + "/php/siteCenterPointAndZoom.php")! as URL)
//        request.httpMethod = "POST"
//        let postString = "_site_name=\(areaName)"
//        request.httpBody = postString.data (using: String.Encoding.utf8)
//
//        let task = URLSession.shared.dataTask(with: request as URLRequest) {
//            data, response, error in
//
//            if error != nil {
//                print("error=\(String(describing: error))")
//                return
//            }
//
//            do {
//
//                let decoder = JSONDecoder()
//                decoder.keyDecodingStrategy = .useDefaultKeys
//                decoder.dataDecodingStrategy = .deferredToData
//                decoder.dateDecodingStrategy = .deferredToDate
//
//                // Get list of points
//                self.startingRegion = try decoder.decode([StartingRegionModel].self, from: data!)
//
//                // dont assign result is empty
//                if !startingRegion.isEmpty {
//                    self.region = MKCoordinateRegion( center: CLLocationCoordinate2D(latitude: Double(startingRegion[0].lat) ?? 0, longitude: Double(startingRegion[0].long) ?? 0),
//                          span: MKCoordinateSpan(latitudeDelta: Double(startingRegion[0].zoom) ?? 0, longitudeDelta: Double(startingRegion[0].zoom) ?? 0))
//                }
//
//            // Debug catching from https://www.hackingwithswift.com/forums/swiftui/decoding-json-data/3024
//            } catch DecodingError.keyNotFound(let key, let context) {
//                Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
//            } catch DecodingError.valueNotFound(let type, let context) {
//                Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
//            } catch DecodingError.typeMismatch(let type, let context) {
//                Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
//            } catch DecodingError.dataCorrupted(let context) {
//                Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
//            } catch let error as NSError {
//                NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
//            }
//        }
//        task.resume()
//    }// end getRegion
}// end view

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(areaName: "Davis", columnName: "area_name", organismName: "Besc-112",
                queryName: "query_search_org_name_by_site")
    }
}
