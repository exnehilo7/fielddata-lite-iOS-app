//
//  MapView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/17/24.
//
//  Updated map view. Based off of MapWithNMEAView. Uses Map MVC. Should serve as a single, combined view for MapWithNMEAView (traveling salesman routes) and MapQCWithNMEAView (show database trip points and mark one blue if a pic has been taken durng the map's session)

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    
    // MARK: Vars
    // swift data
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    @Query var sdTrips: [SDTrip]
    
    @State private var textNotes = ""
    
    // From calling view
    @Bindable var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    var mapMode: String
    var tripOrRouteName: String
    var columnName: String
    var organismName: String
    var queryName: String
    
    
    //MARK: Views
    // Take pic button. Use a swipe-up view.
    var popupCameraButton: some View {
        Button {
            // Reset previously snapped pic if view was swiped down before image was saved
            camera.resetCamera()
            map.showPopover = true
            // Use organism name if exists
            if (map.annotationItems[map.currentAnnoItem].organismName.trimmingCharacters(in: .whitespaces)).count > 0 {
                camera.textNotes = "Organism name:" + map.annotationItems[map.currentAnnoItem].organismName + ";"
            }
        } label: {
            Text("Show Camera")
        }.buttonStyle(.borderedProminent).tint(.orange).popover(isPresented: $map.showPopover) {
            // Show view
            CameraView(map: map, gps: gps, camera: camera, mapMode: mapMode, tripOrRouteName: tripOrRouteName)
        }
    }
    
    
    // MARK: Body
    var body: some View {
        
        VStack{
            
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
                   Text(map.annotationItems[map.currentAnnoItem].organismName).font(.system(size:20)).fontWeight(.bold)
                        // Mark first point on map
                       .onAppear(perform: {
                           map.annotationItems[map.currentAnnoItem].size = 20
                           if mapMode == "route" {
                               // If currentAnnoItem is blue, make it light blue. Else make it red
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
        
        await map.getMapPointsFromDatabase(settings: settings, phpFile: "getMapItemsForApp.php", postString: "_column_name=\(columnName)&_column_value=\(tripOrRouteName)&_org_name=\(organismName)&_query_name=\(queryName)")

    }
    
    // Make sure forward and backward cycling will stay within the annotation's item count.
    private func cycleAnnotations (forward: Bool, _ offset: Int ) {

        var offsetColor: Color
        
        // Get current annotation's color
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
