//
//  MapView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/17/24.
//
//  Updated map view. Based off of MapWithNMEAView. Uses Map MVC. Should serve as a single, combined view for MapWithNMEAView (traveling salesman routes) and MapQCWithNMEAView (show database trip points and mark one blue if a pic has been taken durng the map's session)
//
//  24-JUN-2024: Break up view components into their own vars to make it easier to have different view layouts.

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
    var mapUILayout: String
    
    // For scoring buttons
    @State private var isSelectedZero = false
    @State private var isSelectedOne = false
    @State private var isSelectedTwo = false
    
    
    //MARK: Views
    // Map
    var appleMap: some View {
        VStack {
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
    }
    
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
    
    // CURRENT POINT
    // Current Point Organism Name
    var currentPointOrganismName: some View {
        VStack {
            
            // Show organism name of the selected point
            Text("Current Point:").font(.system(size:15))//.underline()
            
            Text(map.annotationItems[map.currentAnnoItem].organismName).font(.system(size:20)).fontWeight(.bold)
            // Mark first point on map
                .onAppear(perform: {
                    map.annotationItems[map.currentAnnoItem].size = 20
                    if mapMode == "Traveling Salesman" {
                        // If currentAnnoItem is blue, make it light blue. Else make it red
                        if map.annotationItems[map.currentAnnoItem].highlightColor == Color(red: 0, green: 0, blue: 1) {
                            map.annotationItems[map.currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
                        } else {
                            map.annotationItems[map.currentAnnoItem].highlightColor = Color(red: 1, green: 0, blue: 0)
                        }
                    }
                })
        }
    }
    
    // Current Point Coordinates
    var currentPointCoordinates: some View {
        // Show organism's lat and long
        HStack{
            Text("\(map.annotationItems[map.currentAnnoItem].latitude)").font(.system(size:15)).padding(.bottom, 25)
            Text("\(map.annotationItems[map.currentAnnoItem].longitude)").font(.system(size:15)).padding(.bottom, 25)
        }
    }
    
    // ARROW NAVIGATION
    // Previous Point
    var previousPoint: some View {
        // backward
        Button(action: {
            cycleAnnotations(forward: false, 1)
        }, label: {
            VStack {
                Image(systemName: "arrowshape.backward.fill")
                    .font(.system(size: 50))
                Text("Previous")
            }
        })
    }
    
    // Next Point
    var nextPoint: some View {
        // forward
        Button(action:  {
            cycleAnnotations(forward: true, -1)
        }, label: {
            VStack {
                Image(systemName: "arrowshape.forward.fill")
                    .font(.system(size: 50))
                Text("Next")
            }
        })
    }
    
    // SCORING BUTTONS
    var buttonScoreZero: some View {
        
            Button(action: {
                if !isSelectedZero {
                    isSelectedZero = true
                    isSelectedOne = false
                    isSelectedTwo = false
                } else {
                    isSelectedZero = false
                }
            }, label: {
                Text("0")
            })
            .frame(width: 50, height: 50)
            .background(self.isSelectedZero ? Color.green : Color(red: 0.5, green: 0.5, blue: 0.5))
            .foregroundStyle(self.isSelectedZero ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10.0))
            .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(self.isSelectedZero ? .green : Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 2))
        }
        
        var buttonScoreOne: some View {
            
            Button(action: {
                if !isSelectedOne {
                    isSelectedZero = false
                    isSelectedOne = true
                    isSelectedTwo = false
                } else {
                    isSelectedOne = false
                }
            }, label: {
                Text("1")
            })
            .frame(width: 50, height: 50)
            .background(self.isSelectedOne ? Color.green : Color(red: 0.5, green: 0.5, blue: 0.5))
            .foregroundStyle(self.isSelectedOne ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10.0))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(self.isSelectedOne ? .green : Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 2))
        }
        
        var buttonScoreTwo: some View {
            
            Button(action: {
                if !isSelectedTwo {
                    isSelectedZero = false
                    isSelectedOne = false
                    isSelectedTwo = true
                } else {
                    isSelectedTwo = false
                }
            }, label: {
                Text("2")
            })
            .frame(width: 50, height: 50)
            .background(self.isSelectedTwo ? Color.green : Color(red: 0.5, green: 0.5, blue: 0.5))
            .foregroundStyle(self.isSelectedTwo ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10.0))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(self.isSelectedTwo ? .green : Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 2))
        }
    
    
    // MARK: Body
    var body: some View {
        
        VStack{
            
            popupCameraButton

            Spacer()

            appleMap
            
            // If no results, don't display navigation buttons
            if map.hasMapPointsResults {
                VStack {
                    currentPointOrganismName
                    
                    currentPointCoordinates
                    
                    if mapUILayout == "standard" {
                        // Previous / Next Arrows
                        HStack {
                            previousPoint.padding(.trailing, 20)
                            
                            nextPoint.padding(.leading, 20)
                            
                        }.padding(.bottom, 20)
                    }
                    else if mapUILayout == "scoring" {
                        
                        // Previous / Next Arrows
                        HStack {
                            
                            previousPoint.padding(.leading, 20)
                            Spacer()
                            buttonScoreZero
                            buttonScoreOne
                            buttonScoreTwo
                            Spacer()
                            nextPoint.padding(.trailing, 20)
                            
                        }.padding(.bottom, 20)
                    }
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
        if mapMode == "Traveling Salesman" {
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
