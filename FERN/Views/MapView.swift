//
//  MapView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//  Map basics help from https://www.mongodb.com/developer/products/realm/realm-swiftui-maps-location/

import SwiftUI
import MapKit
import SwiftData

/*
 The geocoordinates, organism name, and PK from the database are inserted into
 a MapAnnotationItem which each in trun are added to an array. Cycling through
 the array is done by simple inetger variables. (Apparently Swift doesn't have
 .next() and .previous() for arrays?)
 The starting center is the first MapAnnotationItem item. The zoom level is set
 in the getMapPoints function.
 
*/

struct MapView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
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
    
    // To hold Annotated Map Point Models
    @State private var annotationItems = [MapAnnotationItem]()
    
    // To hold the starting region's coordinates and zoom level
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    
    var body: some View {
        
       // ZStack(alignment: .center) {
            VStack{
                HStack {
                    Spacer()
                    Button ("Refresh"){
                        Task {
                            hasResults = false
                            currentAnnoItem = 0
                            totalAnnoItems = 0
                            annotationItems.removeAll(keepingCapacity: true)
                            await getMapPoints()
                        }
                    }.padding(.trailing, 25)
                }
                // Show map's current position
                Text("lat: \(region.center.latitude), long: \(region.center.longitude). Zoom: \(region.span.latitudeDelta)")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                
                VStack {
                    /* Supposed to supress "Publishing changes from within view updates is not allowed, this will cause undefined behavior." messages in debug, only doubled the messages. Messages could be XCode bug? */
//                    let binding = Binding(
//                        get: {self.region},
//                        set: { newValue in
//                            DispatchQueue.main.async {
//                                self.region = newValue
//                            }
//                        }
//                    )
                    Map(coordinateRegion: $region,
                    interactionModes: .all,
                    showsUserLocation: true,
                    annotationItems: annotationItems
                    ) { item in // add points
                    
                        // Use for custom images and colors:
                        MapAnnotation(coordinate: item.coordinate, content: {
                            Image(systemName: item.systemName)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, item.highlightColor).font(.system(size: item.size))
                        })
                    } // end add points
                }.task { await getMapPoints()}
            // Don't display if no results
            if hasResults {
               VStack {
                   // Show organism name of the selected point
                   Text(annotationItems[currentAnnoItem].organismName).font(.system(size:20)).fontWeight(.bold) //.background(.white)
                       .onAppear(perform: {
                           // Mark first point on map
                           annotationItems[currentAnnoItem].size = 60
                           annotationItems[currentAnnoItem].highlightColor = Color(red: 1, green: 0, blue: 0)
                       }).padding(.bottom, 30)
                   HStack {
                       Button { // backward
                           cycleAnnotations(forward: false, 1)
                       } label: {
                           VStack {
                               Image(systemName: "arrowshape.backward.fill")
                                   .font(.system(size: 50))
                               Text("Previous")
                           }
                       }.padding(.trailing, 20)
                       
                       Button { // forward
                           cycleAnnotations(forward: true, -1)
                       } label: {
                           VStack {
                               Image(systemName: "arrowshape.forward.fill")
                                   .font(.system(size: 50))
                               Text("Next")
                           }
                       }.padding(.leading, 20)
                   }.padding(.bottom, 20)
               } // end vstack
           } // end if hasResults
        }
    } //end body view
    
    
    // Make sure forward and backward cycling will stay within the annotation's item count.
    private func cycleAnnotations (forward: Bool, _ offset: Int ){
        
        if forward {
            if currentAnnoItem < totalAnnoItems{
                currentAnnoItem += 1
                highlightAnnotation(offset)
            }
        }
        else {
            if currentAnnoItem > 0 {
                currentAnnoItem -= 1
                highlightAnnotation(offset)
            }
        }
    }
    
    // Draw attention to selected point. Put previous or next point back to its original state
    private func highlightAnnotation (_ offset: Int){
        annotationItems[currentAnnoItem].size = 60
        annotationItems[currentAnnoItem].highlightColor = Color(red: 1, green: 0, blue: 0)
        annotationItems[currentAnnoItem + offset].size = MapPointSize().size
        annotationItems[currentAnnoItem + offset].highlightColor = Color(white: 0.4745)
    }
    
    // Get points from database
    private func getMapPoints () async {
        
        // get root
//        let htmlRoot = HtmlRootModel().htmlRoot

        guard let url: URL = URL(string: settings[0].databaseURL + "/php/getMapItemsForApp.php") else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "_column_name=\(columnName)&_column_value=\(areaName)&_org_name=\(organismName)&_query_name=\(queryName)"
        
        let postData = postString.data(using: .utf8)
        
            do {
                let (data, _) = try await URLSession.shared.upload(for: request, from: postData!, delegate: nil)
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dataDecodingStrategy = .deferredToData
                decoder.dateDecodingStrategy = .deferredToDate
                
                // Get list of points
                self.searchResults = try decoder.decode([TempMapPointModel].self, from: data)
                
                // dont insert if result is empty
                if !searchResults.isEmpty {
                    
                    totalAnnoItems = (searchResults.count - 1) // adjust for array 0-indexing
                    
                    // Put results in an array
                    for result in searchResults {
                        annotationItems.append(MapAnnotationItem(
                            latitude: Double(result.lat) ?? 0,
                            longitude: Double(result.long) ?? 0,
                            siteId: result.siteId,
                            organismName: result.organismName,
                            systemName: "xmark.diamond.fill"
                        ))
                    }
                    
                    // Set staring regoin to the first point in the list
                    self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: Double(searchResults[0].lat) ?? 0, longitude: Double(searchResults[0].long) ?? 0),
                        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
                    
                    // Don't show items if no data
                    if hasResults == false {
                        hasResults.toggle()
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
            } catch {
                searchResults = []
            }
    }// end getMapPoints
    
}// end MapView view

//struct MapView_Previews: PreviewProvider {
//    static var previews: some View {
//        MapView(areaName: "Davis", columnName: "area_name", organismName: "Besc-112",
//                queryName: "query_search_org_name_by_site")
//    }
//}
