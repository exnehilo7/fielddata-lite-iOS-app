//
//  MapView.swift
//  FERN
//
//  Created by Hopp, Dan on 3/7/24.
//  Map basics help from https://www.mongodb.com/developer/products/realm/realm-swiftui-maps-location/
//  User can choose default GPS or Arrow Gold GPS. If Arrow is selected, use a custom current device position icon.

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

struct MapWithNMEAView: View {
    
    // MARK: Vars
    // swift data
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    // From calling view
    var areaName: String
    var columnName: String
    var organismName: String
    var queryName: String
    
    // Annotation tracking
    @State private var currentAnnoItem = 0 // starting index is 0, so the first "next" will be 1
    @State private var totalAnnoItems = 0
    
    // For map points PHP response
    @State private var mapResults: [TempMapPointModel] = []
    @State private var hasMapPointsResults = false
    
    //Distance and bearing PHP response
    @State private var distanceAndBearingResult: [TempDistanceAndBearingModel] = []
    @State private var hasDistanceAndBearingResult = false
    @State private var distance = "0"
    @State private var bearing = "0"
    
    // Start and end lat and longs
    @State private var startLong = "0"
    @State private var startLat = "0"
    @State private var startLongFloat = 0.0
    @State private var startLatFloat = 0.0
    @State private var endLongFloat = 0.0
    @State private var endLatFloat = 0.0
    
    // Show take pic button
    @State private var showPicButton = false
    
    // Sounds
    let audio = playSound()
    
    // To hold Annotated Map Point Models
    @State private var annotationItems = [MapAnnotationItem]()
    
    // To hold the starting region's coordinates and zoom level
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    
    // Alerts
    @State private var showAlert = false
    @State private var article = Article(title: "Device Feed Error", description: "Check the Bluetooth or satellite connection. If both are OK, try killing and restarting the app.")
    
    // User GPS selection
    @State var gpsModeIsSelected = false
    @State var showArrowGold = false
    
    // GPS -------------------------------------------------------------
    // Arrow Gold
    @ObservedObject var nmea:NMEA = NMEA()
    
    // Default iOS
    @ObservedObject var clLocationHelper = LocationHelper()
    var clLat:String {
        return "\(clLocationHelper.lastLocation?.coordinate.latitude ?? 0.0000)"
    }
    var clLong:String {
        return "\(clLocationHelper.lastLocation?.coordinate.longitude ?? 0.0000)"
    }
    var clHorzAccuracy:String {
        return "\(clLocationHelper.lastLocation?.horizontalAccuracy ?? 0.00)"
    }
    var clVertAccuracy:String {
        return "\(clLocationHelper.lastLocation?.verticalAccuracy ?? 0.00)"
    }
    var clAltitude:String {
        return "\(clLocationHelper.lastLocation?.altitude ?? 0.0000)"
    }
    //------------------------------------------------------------------
    
    //MARK: View Sections
    // GPS Data Display ------------------------------------------------
    // Arrow Gold
    var arrowGpsData: some View {
        VStack {
            Label("EOS Arrow Gold", systemImage: "antenna.radiowaves.left.and.right").underline()
            HStack {
                Text("Lat: ") + Text(nmea.latitude ?? "0.0000")
                Text("Long: ") + Text(nmea.longitude ?? "0.0000")
            }
            HStack {
                Text("Alt (m): ") + Text(nmea.altitude ?? "0.00")
                Text("Horz Acc (m): ") + Text(nmea.accuracy ?? "0.00")
            }
            HStack {
                Text("GPS Used: ") + Text(nmea.gpsUsed ?? "No GPS")
            }
        }.font(.system(size: 12))//.foregroundColor(.white)
    }
    
    // iOS Core Location
    var coreLocationGpsData: some View {
        VStack {
            Label("Standard GPS",  systemImage: "location.fill").underline()
            HStack {
                Text("Lat: ") + Text("\(clLat)")
                Text("Long: ") + Text("\(clLong)")
            }
            
                Text("Alt (m): ") + Text("\(clAltitude)")
            HStack {
                Text("Horz Acc (m): ") + Text("\(clHorzAccuracy)")
                Text("Vert Acc (m): ") + Text("\(clVertAccuracy)")
            }
        }.font(.system(size: 12))//.foregroundColor(.white)
    }
    //------------------------------------------------------------------
    
    // Select GPS mode
    var selectGpsMode: some View {
        HStack {
            HStack{
                Button{
                    gpsModeIsSelected = true
                    // To prevent the device feed from being interruped, disable autosleep
                    UIApplication.shared.isIdleTimerDisabled = true
                    
                    // Convert strings to floats for rounding and comaprisons
                    startLongFloat = (clLong as NSString).doubleValue
                    startLatFloat = (clLat as NSString).doubleValue
                    endLongFloat = annotationItems[currentAnnoItem].longitude
                    endLatFloat = annotationItems[currentAnnoItem].latitude
                    // Round at 6 decimals
                    startLongFloat = round(100000 * startLongFloat) / 100000
                    startLatFloat = round(100000 * startLatFloat) / 100000
                    endLongFloat = round(100000 * endLongFloat) / 100000
                    endLatFloat = round(100000 * endLongFloat) / 100000
                } label: {
                    Label("Use Standard GPS", systemImage: "location.fill")
                }.buttonStyle(.borderedProminent)
            }.padding(.leading, 20)
            Spacer()
            HStack{
                Button{
                    showArrowGold = true
                    // basic core off
                    clLocationHelper.stopUpdatingDefaultCoreLocation()
                    nmea.viewDidLoad()
                    gpsModeIsSelected = true
                    // To prevent the device feed from being interruped, disable autosleep
                    UIApplication.shared.isIdleTimerDisabled = true
                    
                    // Convert strings to floats for rounding and comaprisons
                    startLongFloat = ((nmea.longitude ?? "0.0000") as NSString).doubleValue
                    startLatFloat = ((nmea.latitude ?? "0.0000") as NSString).doubleValue
                    endLongFloat = annotationItems[currentAnnoItem].longitude
                    endLatFloat = annotationItems[currentAnnoItem].latitude
                    // Round at 6 decimals
                    startLongFloat = round(100000 * startLongFloat) / 100000
                    startLatFloat = round(100000 * startLatFloat) / 100000
                    endLongFloat = round(100000 * endLongFloat) / 100000
                    endLatFloat = round(100000 * endLongFloat) / 100000
                } label: {
                    Label("Use Arrow Gold Device", systemImage: "antenna.radiowaves.left.and.right").foregroundColor(.black)
                }.buttonStyle(.borderedProminent).tint(.yellow)
            }.padding(.trailing, 20)
        // (THIS SHOULD CHECK CONSTANTLY?)
        }.onAppear(perform: {
            // if start lat long = end lat long, let user take pic.
            if (startLongFloat == endLongFloat && startLatFloat == endLatFloat) {showPicButton = true; audio.playDing()}
        })
    }
    
    // Where is next? button
    var whereIsNext: some View {
        Button {
            Task {
                // Get starting lat and long
                if showArrowGold {
                    startLong = nmea.longitude ?? "0.0000"
                    startLat = nmea.latitude ?? "0.0000"
                }
                else {
                    startLong = clLong
                    startLat = clLat
                }
                
                // if not default values, call
                if (startLong != "0.0000" && startLat != "0.0000"){
                    await getDistanceAndBearing()
                }
                
                // JUST IN CASE THE CHECK IS NOT AUTO:
                // if start lat long = end lat long, let user take pic.
                if (startLongFloat == endLongFloat && startLatFloat == endLatFloat) {showPicButton = true; audio.playDing()}
            }
        } label: {
            VStack{
                // Flip text based on result
                if !hasDistanceAndBearingResult {
                    Text("Point to next")
                }
                if hasDistanceAndBearingResult {
                    Text("\(bearing)°; \(distance)(m)")
                }
            }
        }.buttonStyle(.borderedProminent).tint(.green).padding(.bottom, 25).font(.system(size:15))
    }
    
    // Take pic button (replace with a show swipe-up? use an auto swipe up?)
    var takePic: some View {
        Button {
            showPicButton = false
        } label: {
            Text("Take pic")
        }.buttonStyle(.borderedProminent).tint(.orange)
    }
    
    
    // MARK: Body
    var body: some View {
        
       // ZStack(alignment: .center) {
            VStack{
                HStack {
                    Spacer()
                    Button ("Reset Route Markers"){
                        Task {
                            hasMapPointsResults = false
                            currentAnnoItem = 0
                            totalAnnoItems = 0
                            annotationItems.removeAll(keepingCapacity: true)
                            await getMapPoints()
                        }
                    }.padding(.trailing, 25)
                }
                // Show device's current position if GPS method is selected
                if gpsModeIsSelected {
                    // show take pic button (or activate swipe-up) if start lat long = dest lat long
                    if !showPicButton {
                        if showArrowGold {
                            arrowGpsData
                        }
                        else {
                            coreLocationGpsData
                        }
                    } else { takePic }
                }
                else {
                    selectGpsMode
                }
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
            if hasMapPointsResults {
               VStack {
                   // Show organism name of the selected point
                   Text(annotationItems[currentAnnoItem].organismName).font(.system(size:20)).fontWeight(.bold) //.background(.white)
                       .onAppear(perform: {
                           // Mark first point on map
                           annotationItems[currentAnnoItem].size = 60
                           annotationItems[currentAnnoItem].highlightColor = Color(red: 1, green: 0, blue: 0)
                       })
                   // Show organism's lat and long
                   HStack{
                       Text("\(annotationItems[currentAnnoItem].latitude)").font(.system(size:15)).padding(.bottom, 25)
                       Text("\(annotationItems[currentAnnoItem].longitude)").font(.system(size:15)).padding(.bottom, 25)
                   }
                   // Previous / Next Arrows
                   HStack {
                       // backward
                       Button(action: {
                           cycleAnnotations(forward: false, 1)
                           // hide distance and bearing
                           hasDistanceAndBearingResult = false
                           // Alert user if Arrow feed has stopped or values are zero
                           if showArrowGold {
                               if nmea.hasNMEAStreamStopped ||
                                    ((nmea.accuracy ?? "0.00") == "0.00" || (nmea.longitude ?? "0.0000") == "0.0000" ||
                                     (nmea.latitude ?? "0.0000") == "0.0000" || (nmea.altitude ?? "0.00") == "0.00")
                               { showAlert = true }
                           }
                       }, label: {
                           VStack {
                               Image(systemName: "arrowshape.backward.fill")
                                   .font(.system(size: 50))
                               Text("Previous")
                           }
                       }).padding(.trailing, 20)
                           .alert(article.title, isPresented: $showAlert, presenting: article) {article in Button("OK"){showAlert = false}} message: {article in Text(article.description)}
                       
                       // forward
                       Button(action:  {
                           cycleAnnotations(forward: true, -1)
                           // hide distance and bearing
                           hasDistanceAndBearingResult = false
                           // Alert user if Arrow feed has stopped or values are zero
                           if showArrowGold {
                               if nmea.hasNMEAStreamStopped ||
                                    ((nmea.accuracy ?? "0.00") == "0.00" || (nmea.longitude ?? "0.0000") == "0.0000" ||
                                     (nmea.latitude ?? "0.0000") == "0.0000" || (nmea.altitude ?? "0.00") == "0.00")
                               { showAlert = true }
                           }
                       }, label: {
                           VStack {
                               Image(systemName: "arrowshape.forward.fill")
                                   .font(.system(size: 50))
                               Text("Next")
                           }
                       }).padding(.leading, 20)
                           .alert(article.title, isPresented: $showAlert, presenting: article) {article in Button("OK"){showAlert = false}} message: {article in Text(article.description)}
                       
                       // Where is next? button
                       whereIsNext
                   }.padding(.bottom, 20)
               } // end vstack
           } // end if hasMapPointsResults
        }
    } //end body view
    
    
    // MARK: Functions
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
                self.mapResults = try decoder.decode([TempMapPointModel].self, from: data)
                
                // dont insert if result is empty
                if !mapResults.isEmpty {
                    
                    totalAnnoItems = (mapResults.count - 1) // adjust for array 0-indexing
                    
                    // Put results in an array
                    for result in mapResults {
                        annotationItems.append(MapAnnotationItem(
                            latitude: Double(result.lat) ?? 0,
                            longitude: Double(result.long) ?? 0,
                            siteId: result.siteId,
                            organismName: result.organismName,
                            systemName: "xmark.diamond.fill"
                        ))
                    }
                    
                    // Set staring regoin to the first point in the list
                    self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: Double(mapResults[0].lat) ?? 0, longitude: Double(mapResults[0].long) ?? 0),
                        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
                    
                    // Don't show items if no data
                    if hasMapPointsResults == false {
                        hasMapPointsResults.toggle()
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
                mapResults = []
            }
    }// end getMapPoints
    
    // get distance and bearing to the next selected map point
    private func getDistanceAndBearing () async {

        guard let url: URL = URL(string: settings[0].databaseURL + "/php/getDistanceAndBearing.php") else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "_start_long=\(startLong)&_start_lat=\(startLat)&_end_long=\(annotationItems[currentAnnoItem].longitude)&_end_lat=\(annotationItems[currentAnnoItem].latitude)"
        
        let postData = postString.data(using: .utf8)
        
            do {
                let (data, _) = try await URLSession.shared.upload(for: request, from: postData!, delegate: nil)
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dataDecodingStrategy = .deferredToData
                decoder.dateDecodingStrategy = .deferredToDate
                
                // Get result
                self.distanceAndBearingResult = try decoder.decode([TempDistanceAndBearingModel].self, from: data)
                
                // dont update vars if result is empty
                if !distanceAndBearingResult.isEmpty {
                    
                    // Put results in an vars
                    for result in distanceAndBearingResult {
                        distance.self = result.distance
                        bearing.self = result.bearing
                    }
                    
                    // Don't show items if no data
                    if hasDistanceAndBearingResult == false {
                        hasDistanceAndBearingResult.toggle()
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
                distanceAndBearingResult = distanceAndBearingResult
            }
    }//end get distance and bearing
    
}// end MapView view

//struct MapView_Previews: PreviewProvider {
//    static var previews: some View {
//        MapView(areaName: "Davis", columnName: "area_name", organismName: "Besc-112",
//                queryName: "query_search_org_name_by_site")
//    }
//}
