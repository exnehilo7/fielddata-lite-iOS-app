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
    @EnvironmentObject var G: GpsBridgingCoordinator
    @EnvironmentObject var M: MapBridgingCoordinator
    
    // swift data
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    @Query var sdTrips: [SDTrip]
    
    @State private var textNotes = ""
    
    // From calling view
    var tripName: String
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
            M.mapController.showPopover = true
            textNotes = "Organism name:" + M.mapController.annotationItems[M.mapController.currentAnnoItem].organismName + ";"
        } label: {
            Text("Show Camera")
        }.buttonStyle(.borderedProminent).tint(.orange).popover(isPresented: $M.mapController.showPopover) {

            // Show view. Pass textNotes.
//            CameraImageView(mapViewIsActive: true, tripName: tripName, showArrowGold: showArrowGold, gpsModeIsSelected: gpsModeIsSelected)//.environmentObject(nmea)
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
                Map(position: $M.mapController.cameraPosition) {
                    UserAnnotation()
                    ForEach(M.mapController.annotationItems) { item in
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
            }.task { await M.mapController.getMapPointsFromDatabase()}  // REMEMEBER TO PASS VARS
        // Don't display if no results
            if M.mapController.hasMapPointsResults {
               VStack {
                   // Show organism name of the selected point
                   Text("Current Point:").font(.system(size:15))//.underline()
                   Text(M.mapController.annotationItems[M.mapController.currentAnnoItem].organismName).font(.system(size:20)).fontWeight(.bold)
                        // Mark first point on map
                       .onAppear(perform: {
                           M.mapController.annotationItems[M.mapController.currentAnnoItem].size = 20
                           // If currentAnnoItem is blue, make it light blue. Else make it red
                           if M.mapController.annotationItems[M.mapController.currentAnnoItem].highlightColor == Color(red: 0, green: 0, blue: 1) {
                               M.mapController.annotationItems[M.mapController.currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
                           } else {
                               M.mapController.annotationItems[M.mapController.currentAnnoItem].highlightColor = Color(red: 1, green: 0, blue: 0)
                           }
                       })
                   // Show organism's lat and long
                   HStack{
                       Text("\(M.mapController.annotationItems[M.mapController.currentAnnoItem].latitude)").font(.system(size:15)).padding(.bottom, 25)
                       Text("\(M.mapController.annotationItems[M.mapController.currentAnnoItem].longitude)").font(.system(size:15)).padding(.bottom, 25)
                   }
                   // Previous / Next Arrows
                   HStack {
                       // backward
                       Button(action: {
                           M.mapController.cycleAnnotations(forward: false, 1)
                       }, label: {
                           VStack {
                               Image(systemName: "arrowshape.backward.fill")
                                   .font(.system(size: 50))
                               Text("Previous")
                           }
                       }).padding(.trailing, 20)
                       
                       // forward
                       Button(action:  {
                           M.mapController.cycleAnnotations(forward: true, -1)
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
}//end MapView view
