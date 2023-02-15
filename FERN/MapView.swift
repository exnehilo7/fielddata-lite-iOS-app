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
    
    @State private var currentAnnoItem = 0 // starting index is 0, so the first "next" will be 1
    @State private var totalAnnoItems = 0
    
    // For map points PHP response
    @State private var searchResults: [TempMapPointModel] = []
    @State private var hasResults = false
    
    // For showing info when a map point is pressed?
    @State private var selectedPoint: MapAnnotationItem?
    
    // To hold Annotated Map Point Models
    @State private var annotationItems = [MapAnnotationItem]()
    
    // To hold the starting region's coordinates and zoom level
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    
    var body: some View {
        
        ZStack(alignment: .center) {
            Map(coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: annotationItems
            ) { item in // add points
                
                // Use for custom images and colors:
                MapAnnotation(coordinate: item.coordinate, content: {
                    Image(systemName: item.systemName)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, .red).font(.system(size: item.size))
                })
            } // end add points
            
            // Show map's current position
            Text("lat: \(region.center.latitude), long: \(region.center.longitude). Zoom: \(region.span.latitudeDelta)")
                .font(.caption)
                .fontWeight(.semibold)
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
                Button { // backward
                    cycleAnnotations(forward: false)
                    annotationItems[currentAnnoItem].size = 60
                    annotationItems[currentAnnoItem + 1].size = MapPointSize().size
                    print(annotationItems[currentAnnoItem].organismName)
                } label: {
                    Image(systemName: "arrowshape.backward.fill")
                        .font(.system(size: 50))
                        .grayscale(0.85)
                }.offset(y: 580).offset(x: -75)
        
                Button { // forward
                    cycleAnnotations(forward: true)
                    // Draw attention to selected point
                    annotationItems[currentAnnoItem].size = 60
                    // Put previous' point back to its original state
                    annotationItems[currentAnnoItem - 1].size = MapPointSize().size
                    print(annotationItems[currentAnnoItem].organismName)

                    
                } label: {
                    Image(systemName: "arrowshape.forward.fill")
                        .font(.system(size: 50))
                        .grayscale(0.85)
                }.offset(y: 580).offset(x: 75)
                
                
            }
            // For async acticity, use .task instead of .onAppear
        }.task { await getMapPoints()}//.task { await getRegion()}
    }
    
    
    // Make sure forward and backward cycling will stay within the annotation's item count
    func cycleAnnotations (forward: Bool ){
        
        if forward {
            if currentAnnoItem < totalAnnoItems{
                currentAnnoItem += 1
            }
        }
        else {
            if currentAnnoItem > 0 {
                currentAnnoItem -= 1
            }
        }
    }
    
    func getMapPoints () async {
        
        // get root
        let htmlRoot = HtmlRootModel()
        
        // pass name of search column to use
        let request = NSMutableURLRequest(url: NSURL(string: htmlRoot.htmlRoot + "/php/getMapItemsForApp.php")! as URL)
        request.httpMethod = "POST"
        let postString = "_column_name=\(columnName)&_column_value=\(areaName)&_org_name=\(organismName)&_query_name=\(queryName)"
        
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
    
}// end view

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(areaName: "Davis", columnName: "area_name", organismName: "Besc-112",
                queryName: "query_search_org_name_by_site")
    }
}
