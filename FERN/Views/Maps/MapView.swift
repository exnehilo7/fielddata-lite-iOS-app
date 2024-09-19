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

//extension AnyTransition {
//    static var moveAndFade: AnyTransition {
//        .asymmetric(
//            insertion: .scale.combined(with: .opacity),
//            removal: .scale.combined(with: .opacity)
//        )
//    }
//}

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
    @Bindable var upload: FileUploadClass
    var mapMode: String
    var tripOrRouteName: String
    var columnName: String
    var organismName: String
    var queryName: String
    @Bindable var measurements: MeasurementsClass
    
    // scoring
    @State private var isScoringActive = false
    @State private var showScoreTextField = false
    @State private var showMeasurementSelect = false
//    @ObservedObject var measurements = Measurements()
    
    
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
                // Add temp points?
                ForEach(map.tempMapPoints) { item in
                    Annotation(item.organismName, coordinate: item.coordinate) {Image(systemName: item.systemName)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.orange, item.highlightColor).font(.system(size: item.size))}
                }
            }.mapStyle(.standard)//(.hybrid(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
                MapUserLocationButton()
            }
        }.task {
            await getMapPoints()
        }
    }
    
    // Take pic button. Use a swipe-up view.
    var popupCameraButton: some View {
        Button {
            // Reset previously snapped pic if view was swiped down before image was saved
            camera.resetCamera()
            map.showPopover = true
            // Use organism name if exists
            if (map.annotationItems[map.currentAnnoItem].organismName.trimmingCharacters(in: .whitespaces)).count > 0 {
                camera.textNotes = map.annotationItems[map.currentAnnoItem].organismName
            }
        } label: {
            Text("Show Camera")
        }.buttonStyle(.borderedProminent).tint(.orange).popover(isPresented: $map.showPopover) {
            // Show view
            CameraView(map: map, gps: gps, camera: camera, mapMode: mapMode, tripOrRouteName: tripOrRouteName, measurements: measurements, openedFromMapView: true)
        }
    }
    
    // MARK: CURRENT POINT
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
    
    // MARK: ARROW NAVIGATION
    // Previous Item
    var previousItem: some View {
        // backward
        Button(action: {
            withAnimation {
                if isScoringActive {
                    measurements.cycleScoringTypes(forward: false)
                } else {
                    cycleAnnotations(forward: false, 1)
                }
            }
        }, label: {
            VStack {
                Image(systemName: "arrowshape.backward.fill")
                    .font(.system(size: 50))
            }
        })
    }
    
    // Next Item
    var nextItem: some View {
        // forward
        Button(action:  {
            withAnimation {
                if isScoringActive {
                    measurements.cycleScoringTypes(forward: true)
                } else {
                    cycleAnnotations(forward: true, -1)
                }
            }
        }, label: {
            VStack {
                Image(systemName: "arrowshape.forward.fill")
                    .font(.system(size: 50))
            }
        })
    }
    
    
    // MARK: SCORING
    // Scoring Button
    var scoringButton: some View {
        Button {
            Task {
                isScoringActive.toggle()
                withAnimation {
                    if isScoringActive {
                        measurements.setMeasurementVars()
                        showScoreTextField = true
                    } else {
                        // Write current measurement to vars
                        measurements.assignCurrentScoreForSave()
                        
                        // Put scores into JSON format, write to CSV
                        let scoresJSON = measurements.createScoreJSON()
                        map.saveScoreToTextFile(tripOrRouteName: tripOrRouteName, longitude: "\(map.annotationItems[map.currentAnnoItem].longitude)", latitude: "\(map.annotationItems[map.currentAnnoItem].latitude)", score: scoresJSON)
                        
                        // Hide
                        showScoreTextField = false
                    }
                }
            }
        } label: {
            HStack {
                if isScoringActive {
                    Text("Done")//.font(.system(size:12))
                } else { Text("Score")}
            }
            .frame(width: 150, height: 50)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    // Numberpad Button
    struct numberpadButton: View {
        var labelAndValue: String
        var width: CGFloat
        var height: CGFloat
        @Binding var score: String
        var isBackspace: Bool
        
        var body: some View {
            Button(action: {
                if isBackspace {
                    if score != "" {
                        score.removeLast()
                    }
                } else {
                    score.append(labelAndValue)
                }
            }, label: {
                if isBackspace {
                    Image(systemName: "arrow.left").bold(false).foregroundColor(.white).font(.system(size:35))
                } else {
                    Text(labelAndValue).font(.system(size:40))
                }
            })
            .frame(width: width, height: height)
            .background(Color(red: 0.5, green: 0.5, blue: 0.5))
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10.0))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 2))
        }
    }
    
    // unit type picker
    var unitTypePicker: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "chevron.compact.down").bold(false).foregroundColor(.white)
                    Text("Swipe down when finished").bold(false)
                    Image(systemName: "chevron.compact.down").bold(false).foregroundColor(.white)
                }
                Picker("Unit", selection: $measurements.selectedUnit) {
                    ForEach(measurements.units, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
        .navigationTitle("Select unit of measurement")
    }
    
    // Measurements/scoring displayed values
    var measurementsView: some View {
        HStack {
            Text("\(measurements.scoreType):").padding().padding()
            Text(measurements.score)
            Button {
                showMeasurementSelect.toggle()
            } label: {
                HStack {
                    Text("\(measurements.selectedUnit)")
                    Image(systemName: "arrow.up.and.down").bold(false).foregroundColor(.white)
                }
                .frame(minWidth: 20, maxWidth: 60, minHeight: 20, maxHeight: 23)
                .background(Color.gray)
                .foregroundColor(.white)
                .padding(.horizontal)
            }.popover(isPresented: $showMeasurementSelect) { unitTypePicker }
        }
    }
    
    // Numberpad layout
    var numberpad: some View {
        // Numberpad
        return VStack {
            // 7 - 9
            HStack {
                numberpadButton(labelAndValue: "7", width: 50, height: 50, score: $measurements.score, isBackspace: false)
                numberpadButton(labelAndValue: "8", width: 50, height: 50, score: $measurements.score, isBackspace: false)
                numberpadButton(labelAndValue: "9", width: 50, height: 50, score: $measurements.score, isBackspace: false)
            }
            // 4 - 6
            HStack {
                numberpadButton(labelAndValue: "4", width: 50, height: 50, score: $measurements.score, isBackspace: false)
                numberpadButton(labelAndValue: "5", width: 50, height: 50, score: $measurements.score, isBackspace: false)
                numberpadButton(labelAndValue: "6", width: 50, height: 50, score: $measurements.score, isBackspace: false)
            }
            // 1 - 3
            HStack {
                numberpadButton(labelAndValue: "1", width: 50, height: 50, score: $measurements.score, isBackspace: false)
                numberpadButton(labelAndValue: "2", width: 50, height: 50, score: $measurements.score, isBackspace: false)
                numberpadButton(labelAndValue: "3", width: 50, height: 50, score: $measurements.score, isBackspace: false)
            }
            // 0, ., backspace
            HStack {
                numberpadButton(labelAndValue: "0", width: 50, height: 50, score: $measurements.score, isBackspace: false)
                numberpadButton(labelAndValue: ".", width: 50, height: 50, score: $measurements.score, isBackspace: false)
                numberpadButton(labelAndValue: "", width: 50, height: 50, score: $measurements.score, isBackspace: true)
            }.padding(.bottom, 20)
        }
    }
    
    // Combine the two to workaround that pesky return
    var measurementsAndNumberpad: some View {
        VStack {
            measurementsView
            numberpad
        }
    }
    
    // MARK: Body
    var body: some View {
        
        VStack{
            
            popupCameraButton

            Spacer()

            appleMap.frame(minWidth: 300, maxWidth: .infinity, minHeight: 50, maxHeight: .infinity)
            
            // If no results, don't display navigation buttons
            if map.hasMapPointsResults {
                VStack {
                    currentPointOrganismName
                    
                    currentPointCoordinates
                        
                    // Scoring view
                    if showScoreTextField {
                        measurementsAndNumberpad.transition(.scale.combined(with: .opacity))
                    }
                    // Previous / Next Arrows with Scoring button
                    HStack {
                        
                        previousItem.padding(.trailing, 20)
                        scoringButton
                        nextItem.padding(.leading, 20)

                    }.padding(.bottom, 20)
                } //end selected item info and arrow buttons VStack
           } //end if hasMapPointsResults
        } //end VStack
        .onAppear(perform: {
                map.createScoringFileForTheDay(tripOrRouteName: tripOrRouteName)
        })
    } //end body view
    
    private func getMapPoints() async {
        await map.getMapPointsFromDatabase(settings: settings, phpFile: "getMapItemsForApp.php", postString: "_column_name=\(columnName)&_column_value=\(tripOrRouteName)&_org_name=\(organismName)&_query_name=\(queryName)")
    }
    
    private func refreshMapPoints() async {
        await map.refreshMap(settings: settings, phpFile: "getMapItemsForApp.php", postString: "_column_name=\(columnName)&_column_value=\(tripOrRouteName)&_org_name=\(organismName)&_query_name=\(queryName)")
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
                // clear score vars
                measurements.clearMeasurementVars()
            }
        }
        else {
            // offset should be 1
            if map.currentAnnoItem > 0 {
                map.currentAnnoItem -= 1
                highlightMapAnnotation(offset, offsetColor)
                // clear score vars
                measurements.clearMeasurementVars()
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
        // If map is a trip, color the previous item blue
        else if mapMode == "View Trip" {
            // If moving forward, color the previous item blue
            if offset == -1 {
                map.annotationItems[map.currentAnnoItem + offset].highlightColor = Color(red: 0, green: 0, blue: 1)
            }
        }
    }
}//end MapView view
