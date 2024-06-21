//
//  MapView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/17/24.
//
//  Updated map view. Based off of MapWithNMEAView. Uses Map MVC. Should hopefully be able to serve as a single, combined view for MapWithNMEAView (traveling salesman routes) and MapQCWithNMEAView (show database trip points and mark one blue if a pic has been taken durng the map's session)

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    
    // MARK: Vars
    // Bridging coordinator
//    @EnvironmentObject var G: GpsBridgingCoordinator
//    @EnvironmentObject var M: MapBridgingCoordinator
//    @EnvironmentObject var C: CameraBridgingCoordinator
    
    // swift data
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    @Query var sdTrips: [SDTrip]
    
    @State private var textNotes = ""
//    @State private var annotationItems = [MapAnnotationItem]()
    
    // From calling view
    @Bindable var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    var mapMode: String
    var tripOrRouteName: String
    var columnName: String
    var organismName: String
    var queryName: String
    
    // Annotation tracking
//    @State private var currentAnnoItem = 0 // starting index is 0, so the first "next" will be 1
//    @State private var totalAnnoItems = 0
    
    // For map points PHP response
//    @State private var mapResults: [TempMapPointModel] = []
//    @State private var hasMapPointsResults = false

    
    // Show take pic button and popover view
//    @State private var showPopover = false
    
    
    // To hold Annotated Map Point Models
//    @State private var annotationItems = [MapAnnotationItem]()
    
    // To hold the starting region's coordinates and zoom level
//    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    // For 17.0's MapKit SDK change
//    @State private var cameraPosition = MapCameraPosition.region(
//        MKCoordinateRegion(
//            center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
//            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
//        )
//    )
//    // For map reloads
//    @State private var currentCameraPosition: MapCameraPosition?
    
    
//    // Alerts
//    @State private var showAlert = false
//    @State private var article = Article(title: "Device Feed Error", description: "Check the Bluetooth or satellite connection. If both are OK, try killing and restarting the app.")
    
    // User GPS selection
//    @State var gpsModeIsSelected = false  // THESE TWO WILL BE MERGED INTO SETTINGS' useBluetoothDevice
//    @State var showArrowGold = false
//    var showArrowGold:Bool
//    var gpsModeIsSelected:Bool

    
    //MARK: Sections from View's Original Setup
    // GPS -------------------------------------------------------------
    // Arrow Gold
//    @EnvironmentObject var nmea:NMEA
//    
//    // Default iOS
//    @ObservedObject var clLocationHelper = LocationHelper() // WILL BE GRABBED FROM GPS MVC

    

    // Take pic button. Use a swipe-up view.
    var popupCameraButton: some View {
        Button {
            // Reset previously snapped pic if view was swiped down before image was saved
            camera.resetCamera()
            map.showPopover = true
//            textNotes = "Organism name:" + self.annotationItems[map.currentAnnoItem].organismName + ";"
            if (map.annotationItems[map.currentAnnoItem].organismName.trimmingCharacters(in: .whitespaces)).count > 0 {
                camera.textNotes = "Organism name:" + map.annotationItems[map.currentAnnoItem].organismName + ";"
            }
        } label: {
            Text("Show Camera")
        }.buttonStyle(.borderedProminent).tint(.orange).popover(isPresented: $map.showPopover) {
            // Show view. Pass textNotes.
            CameraView(map: map, gps: gps, camera: camera, mapMode: mapMode, tripOrRouteName: tripOrRouteName)
//                .environmentObject(G)
//                .environmentObject(M)
//                .environmentObject(C)
        }
    }
    
    
    // MARK: Body
    var body: some View {
        
       // ZStack(alignment: .center) {
        VStack{

            // Activate MVCs?
            HStack{}
            
            popupCameraButton

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
                // 17.0's new MapKit SDK:
                Map(position: $map.cameraPosition) {
                    UserAnnotation()
//                    ForEach(self.annotationItems) { item in
                    ForEach(map.annotationItems) { item in
                        Annotation(item.organismName, coordinate: item.coordinate) {Image(systemName: item.systemName)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, item.highlightColor).font(.system(size: item.size))}
                    }
                }.mapStyle(.standard)//(.hybrid(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }
            }.task { await getMapPoints()}
        // Don't display if no results
            if map.hasMapPointsResults {
               VStack {
                   // Show organism name of the selected point
                   Text("Current Point:").font(.system(size:15))//.underline()
//                   Text(self.annotationItems[map.currentAnnoItem].organismName).font(.system(size:20)).fontWeight(.bold)
//                        // Mark first point on map
//                       .onAppear(perform: {
//                           self.annotationItems[map.currentAnnoItem].size = 20
                   Text(map.annotationItems[map.currentAnnoItem].organismName).font(.system(size:20)).fontWeight(.bold)
                        // Mark first point on map
                       .onAppear(perform: {
                           map.annotationItems[map.currentAnnoItem].size = 20
                           if mapMode == "route" {
                               // If currentAnnoItem is blue, make it light blue. Else make it red
//                               if self.annotationItems[map.currentAnnoItem].highlightColor == Color(red: 0, green: 0, blue: 1) {
//                                   self.annotationItems[map.currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
//                               } else {
//                                   self.annotationItems[map.currentAnnoItem].highlightColor = Color(red: 1, green: 0, blue: 0)
//                               }
//                           }
//                       })
//                   // Show organism's lat and long
//                   HStack{
//                       Text("\(self.annotationItems[map.currentAnnoItem].latitude)").font(.system(size:15)).padding(.bottom, 25)
//                       Text("\(self.annotationItems[map.currentAnnoItem].longitude)").font(.system(size:15)).padding(.bottom, 25)
//                   }
                               if map.annotationItems[map.currentAnnoItem].highlightColor == Color(red: 0, green: 0, blue: 1) {
                                   map.annotationItems[map.currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
                               } else {
                                   map.annotationItems[map.currentAnnoItem].highlightColor = Color(red: 1, green: 0, blue: 0)
                               }
                           }
                       })
                   // Show organism's lat and long
                   HStack{
                       Text("\(map.annotationItems[map.currentAnnoItem].latitude)").font(.system(size:15)).padding(.bottom, 25)
                       Text("\(map.annotationItems[map.currentAnnoItem].longitude)").font(.system(size:15)).padding(.bottom, 25)
                   }
                   // Previous / Next Arrows
                   HStack {
                       // backward
                       Button(action: {
                           cycleAnnotations(forward: false, 1)
                       }, label: {
                           VStack {
                               Image(systemName: "arrowshape.backward.fill")
                                   .font(.system(size: 50))
                               Text("Previous")
                           }
                       }).padding(.trailing, 20)
                       
                       // forward
                       Button(action:  {
                           cycleAnnotations(forward: true, -1)
                       }, label: {
                           VStack {
                               Image(systemName: "arrowshape.forward.fill")
                                   .font(.system(size: 50))
                               Text("Next")
                           }
                       }).padding(.leading, 20)
                   }.padding(.bottom, 20)
               } //end selected item info and arrow buttons VStack
           } //end if hasMapPointsResults
        } //end VStack
    } //end body view
    
    private func getMapPoints() async {
        
//        self.annotationItems = 
        await map.getMapPointsFromDatabase(settings: settings, phpFile: "getMapItemsForApp.php", postString: "_column_name=\(columnName)&_column_value=\(tripOrRouteName)&_org_name=\(organismName)&_query_name=\(queryName)")

    }
    
    // Make sure forward and backward cycling will stay within the annotation's item count.
    private func cycleAnnotations (forward: Bool, _ offset: Int ) {

        var offsetColor: Color
        
        // Get current annotation's color
//        offsetColor = annotationItems[map.currentAnnoItem].highlightColor
        offsetColor = map.annotationItems[map.currentAnnoItem].highlightColor
        
        if forward {
            // offset should be -1
            if map.currentAnnoItem < map.totalAnnoItems {
                map.currentAnnoItem += 1
                highlightMapAnnotation(offset, offsetColor)
            }
        }
        else {
            // offset should be 1
            if map.currentAnnoItem > 0 {
                map.currentAnnoItem -= 1
                highlightMapAnnotation(offset, offsetColor)
            }
        }
    }
    
    // Draw attention to selected point. Put previous or next point back to its original state
    private func highlightMapAnnotation (_ offset: Int, _ currentColor: Color){

//        annotationItems[map.currentAnnoItem].size = 20
//        annotationItems[map.currentAnnoItem + offset].size = MapPointSize().size
//        
//        // if map is for a route, use the grey-blue-red setup
//        if mapMode == "route" {
//            // If currentAnnoItem is blue, make it light blue. Else make it red
//            if annotationItems[map.currentAnnoItem].highlightColor == Color(red: 0, green: 0, blue: 1) {
//                annotationItems[map.currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
//            } else {
//                annotationItems[map.currentAnnoItem].highlightColor = Color(red: 1, green: 0, blue: 0)
//            }
//            
//            // If offsetColor is red, make it grey. Else make it blue
//            if annotationItems[map.currentAnnoItem + offset].highlightColor == Color(red: 1, green: 0, blue: 0) {
//                annotationItems[map.currentAnnoItem + offset].highlightColor = Color(red: 0.5, green: 0.5, blue: 0.5)
//            } else {
//                annotationItems[map.currentAnnoItem + offset].highlightColor = Color(red: 0, green: 0, blue: 1)
//            }
//        }
        
        map.annotationItems[map.currentAnnoItem].size = 20
        map.annotationItems[map.currentAnnoItem + offset].size = MapPointSize().size
        
        // if map is for a route, use the grey-blue-red setup
        if mapMode == "route" {
            // If currentAnnoItem is blue, make it light blue. Else make it red
            if map.annotationItems[map.currentAnnoItem].highlightColor == Color(red: 0, green: 0, blue: 1) {
                map.annotationItems[map.currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
            } else {
                map.annotationItems[map.currentAnnoItem].highlightColor = Color(red: 1, green: 0, blue: 0)
            }
            
            // If offsetColor is red, make it grey. Else make it blue
            if map.annotationItems[map.currentAnnoItem + offset].highlightColor == Color(red: 1, green: 0, blue: 0) {
                map.annotationItems[map.currentAnnoItem + offset].highlightColor = Color(red: 0.5, green: 0.5, blue: 0.5)
            } else {
                map.annotationItems[map.currentAnnoItem + offset].highlightColor = Color(red: 0, green: 0, blue: 1)
            }
        }
    }
    
}//end MapView view
