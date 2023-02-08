//
//  MapView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//  Map basics help from https://www.mongodb.com/developer/products/realm/realm-swiftui-maps-location/

import SwiftUI
import MapKit

// Within the database funcion, divide general region's zoom level by 125,000 to
// adjust for the table's CesiumJS value.
struct MapView: View {
    
    // From calling view
    var areaName: String
    var columnName: String
    var organismName: String
    
    @State var currentAnnoItem = 1
    @State var totalAnnoItems = 0
    
    // For map points PHP response
    @State var searchResults: [TempMapPointModel] = []
    @State var hasResults = false
    
    
    // For starting region and zooom level PHP response
    @State var startingRegion: [StartingRegionModel] = []
    
    // To hold Annotated Map Point Models
    @State var annotationItems = [MapAnnotationItem]()
    
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
    
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    
    
    var body: some View {
        
        
        ZStack {
            Map(coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: annotationItems
            ) { item in // add points
                // A vanilla point:
//                 MapMarker(coordinate: item.coordinate)
                
                // Use for custom images and colors:
                MapAnnotation(coordinate: item.coordinate) {
                    Image(systemName: "tree.circle") //leaf.circle
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, .red).font(.system(size: 35))
                }
            } // end add points
            Text("lat: \(region.center.latitude), long: \(region.center.longitude). Zoom: \(region.span.latitudeDelta)")
                .font(.caption)
                .fontWeight(.semibold)
//                .foregroundColor(.red)
                .offset(y: -350)
                .padding()
            // Don't display if no results
            if hasResults {
                Button("< Previous"){
                    print(annotationItems[currentAnnoItem].siteId)
                    currentAnnoItem -= 1
                }.buttonStyle(.borderless)
                    .offset(y: 325).offset(x: -50)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Button("Next >"){
                    print(annotationItems[currentAnnoItem].siteId)
                    currentAnnoItem += 1
                }.buttonStyle(.borderless)
                    .offset(y: 325).offset(x: 50)
                    .font(.title3)
                    .fontWeight(.bold)
                // Button images demo:
                Button {
                    print("pressed")
                } label: {
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 50))
                }
            }
        }.onAppear(perform: getMapPoints).onAppear(perform: getRegion)
    }
    
    // Function to make sure forward and backward stay within annotation's item count
    
    func getMapPoints () {
        
        // get root
        let htmlRoot = HtmlRootModel()
        
        // pass name of search column to use
        let request = NSMutableURLRequest(url: NSURL(string: htmlRoot.htmlRoot + "/php/searchOrgNameBySite.php")! as URL)
        request.httpMethod = "POST"
        let postString = "_column_name=\(columnName)&_column_value=\(areaName)&_org_name=\(organismName)"
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
                    
                    totalAnnoItems = searchResults.count
                    
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
                                          organismName: result.organismName
                                          ))
                        }
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
    
    func getRegion () {
        
        // get root
        let htmlRoot = HtmlRootModel()
        
        // pass name of search column to use
        let request = NSMutableURLRequest(url: NSURL(string: htmlRoot.htmlRoot + "/php/siteCenterPointAndZoom.php")! as URL)
        request.httpMethod = "POST"
        let postString = "_site_name=\(areaName)"
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
                self.startingRegion = try decoder.decode([StartingRegionModel].self, from: data!)
                
                // dont assign result is empty
                if !startingRegion.isEmpty {
                    self.region = MKCoordinateRegion( center: CLLocationCoordinate2D(latitude: Double(startingRegion[0].lat) ?? 0, longitude: Double(startingRegion[0].long) ?? 0),
                          span: MKCoordinateSpan(latitudeDelta: Double(startingRegion[0].zoom) ?? 0, longitudeDelta: Double(startingRegion[0].zoom) ?? 0))
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
    }// end getRegion
}// end view

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(areaName: "Davis", columnName: "area_name", organismName: "Besc-112")
    }
}
