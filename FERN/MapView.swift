//
//  MapView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//  Map basics help from https://www.mongodb.com/developer/products/realm/realm-swiftui-maps-location/

import SwiftUI
import MapKit


struct MapView: View {
    
    var areaName: String
    var columnName: String
    var organismName: String
    @State var searchResults: [TempMapPointModel] = []
    @State var hasResults = false
    
//    var annotationItems: [Any] = [MapAnnotationItem()]
    @State var annotationItems = [MapAnnotationItem]()
    
    // Set startig geo loc
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
    
    // Set general region at launch
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: MapDefaults.latitude, longitude: MapDefaults.longitude),
        span: MKCoordinateSpan(latitudeDelta: MapDefaults.zoom, longitudeDelta: MapDefaults.zoom))
    
    
    var body: some View {
        
        
        VStack {
            Text("lat: \(region.center.latitude), long: \(region.center.longitude). Zoom: \(region.span.latitudeDelta)")
                .font(.caption)
                .padding()
            Map(coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
//                annotationItems: annotationItems
                annotationItems: annotationItems
            ) { item in
                // A vanilla point:
//                 MapMarker(coordinate: item.coordinate)
                
                // Use for custom images and colors:
                MapAnnotation(coordinate: item.coordinate) {
                    Image(systemName: "tree.circle") //leaf.circle
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, .red).font(.system(size: 35))
                }
            }
        }.onAppear(perform: getMapPoints)
    }
    
    func getMapPoints () {
        
        // get root
        let htmlRoot = HtmlRootModel()
        
        // pass name of search column to use
        let request = NSMutableURLRequest(url: NSURL(string: htmlRoot.htmlRoot + "/php/searchOrgNameByArea.php")! as URL)
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
                
                // convert JSON response into class model as an array
                self.searchResults = try decoder.decode([TempMapPointModel].self, from: data!)
                
                // dont show link if result is empty
                if !searchResults.isEmpty {
//                    if hasResults == false {
//                        hasResults.toggle()
//                    }
//                    let annotationItems = [
                        
                    // Put results in an array
                        for result in searchResults {
                            annotationItems.append(MapAnnotationItem(
                                latitude: Double(result.lat) ?? 0,
                            longitude: Double(result.long) ?? 0,
                                          siteId: result.siteId,
                                          organismName: result.organismName
                                          ))
                        }
                    
//                    for item in annotationItems {
//                       print(item)
//                    }
                    
//                        ForEach (searchResults, id: \.self) {result in
//                            MapAnnotationItem(coordinate: CLLocationCoordinate2D(
//                                latitude: 35.931,
//                                longitude: -84.31528),
//                                              siteId: result.siteId,
//                                              organismName: result.organismName
//                                              )
//                        }
                        
//                        ]
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
}// end view

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(areaName: "Davis", columnName: "area_name", organismName: "Besc-113_")
    }
}
