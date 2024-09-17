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
    var scoringView = ScoringView()
    
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
//    var mapUILayout: String
    
    // scoring
    @State private var isScoringActive = false
    @State private var showScoreTextField = false
    @State private var showMeasurementSelect = false
    @ObservedObject var measurements = Measurements()
    
    
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
            }//.frame(minHeight: 50) // Make map height dynamic
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
            withAnimation {
                if isScoringActive {
                    cycleAnnotations(forward: false, 1)
                    // Hide upload button
                    Task {
                        await upload.setShowUploadButtonToFalse()
                    }
                } else {
                    cycleScoringTypes(forward: false)
                }
            }
        }, label: {
            VStack {
                Image(systemName: "arrowshape.backward.fill")
                    .font(.system(size: 50))
//                Text("Previous")
            }
        })
    }
    
    // Next Point
    var nextPoint: some View {
        // forward
        Button(action:  {
            withAnimation {
                if isScoringActive {
                    cycleAnnotations(forward: true, -1)

//                    Task {
//                        await upload.setShowUploadButtonToTrue()
//                    }

                } else {
                    cycleScoringTypes(forward: true)
                }
            }
        }, label: {
            VStack {
                Image(systemName: "arrowshape.forward.fill")
                    .font(.system(size: 50))
//                Text("Next")
            }
        })
    }
    
//    //UPLOAD BUTTON
//    var uploadScoreButton: some View {
//        Button {
//            Task {
//                await upload.resetVars()
//                await upload.setShowPopoverToTrue()
//            }
//        } label: {
//            HStack {
//               Text("Upload Scores").font(.system(size:12))
//           }
//           .frame(minWidth: 0, maxWidth: 100, minHeight: 0, maxHeight: 50)
//           .background(Color.orange)
//           .foregroundColor(.white)
//           .cornerRadius(10)
//           .padding(.horizontal)
//           .popover(isPresented: $upload.showPopover) {
//               UploadFilesView(tripName: tripOrRouteName, uploadURL: settings[0].uploadScriptURL, cesiumURL: settings[0].cesiumURL, upload: upload)
//           }
//        }
//    }
    
//  SCORING
    var scoringView: some View {
        // Score and numberpad
//        if showScoreTextField {
            // Score, label, and type
            HStack {
                Text("\(scoreType):").padding().padding()
                Text(score)
                Button {
                    showMeasurementSelect.toggle()
                } label: {
                    HStack {
                        Text("\(selectedUnit)")
                        Image(systemName: "arrow.up.and.down").bold(false).foregroundColor(.white)//.font(.system(size:35))//arrow.up.and.down
                    }
                    .frame(minWidth: 20, maxWidth: 60, minHeight: 20, maxHeight: 23)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                }.popover(isPresented: $showMeasurementSelect) { lengthTypePicker }
            }
            // Numberpad
            VStack {
                // 7 - 9
                HStack {
                    numberpadButton(labelAndValue: "7", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "8", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "9", width: 50, height: 50, score: $score, isBackspace: false)
                }
                // 4 - 6
                HStack {
                    numberpadButton(labelAndValue: "4", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "5", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "6", width: 50, height: 50, score: $score, isBackspace: false)
                }
                // 1 - 3
                HStack {
                    numberpadButton(labelAndValue: "1", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "2", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "3", width: 50, height: 50, score: $score, isBackspace: false)
                }
                // ., 0, backspace
                HStack {
                    numberpadButton(labelAndValue: ".", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "0", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "", width: 50, height: 50, score: $score, isBackspace: true)
                }.padding(.bottom, 20)
            }
//        }
    }
    
    // Scoring Button
    var scoringButton: some View {
        Button {
            Task {
                isScoringActive.toggle()
                if isScoringActive {
                    measurements.setMeasurementVars()
                    showScoreTextField = true
                } else {
                    // Assign score to current type's variable, write vars to CSV, reset vars (except score type units)
                    
                    // Hide
                    showScoreTextField = false
                }
            }
        } label: {
            HStack {
                if isScoringActive {
                    Text("Done")//.font(.system(size:12))
                } else { Text("Score")}
            }
            .frame(minWidth: 0, maxWidth: 150, minHeight: 0, maxHeight: 50)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    //Numberpad Button
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
    
    // length type picker
    var lengthTypePicker: some View {
        Form {
            
            Section {
                HStack {
                    Image(systemName: "chevron.compact.down").bold(false).foregroundColor(.white)
                    Text("Swipe down when finished").bold(false)
                }
                Picker("Unit", selection: $selectedUnit) {
                    ForEach(units, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
        .navigationTitle("Select unit of measurement")
    }
    
//    // Scoring measurement type navigation
//    func cycleScoringTypes(forward: Bool) {
//           
//       let count = measurementLables.count
//
//       if forward {
//           // Is end reached?
//           if count == currMeasureLabel + 1 {
//               // do nothing
//           } else {
//               exchangeScoreValues(dir: 1)
//           }
//           
//       } else {
//           // Is start reached?
//           if currMeasureLabel == 0 {
//               // do nothing
//           } else {
//               exchangeScoreValues(dir: -1)
//           }
//       }
//    }
//    private func exchangeScoreValues(dir: Int) {
//       // Assign score to current type's variable
//       scoresToSave[currMeasureLabel] = score
//       unitsToSave[currMeasureLabel] = selectedUnit
//       
//       // Move to the next score
//       currMeasureLabel = currMeasureLabel + dir
//       scoreType = measurementLables[currMeasureLabel]
//       score = scoresToSave[currMeasureLabel]
//       selectedUnit = unitsToSave[currMeasureLabel]
//    }
    
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
                        
                    // Scoring view main view
                    if showScoreTextField {
                        scoringView
                    }
                    // Previous / Next Arrows with Scoring button
                    HStack {
                        
                        previousPoint.padding(.leading, 20)
                        Spacer()
                        scoringButton
                        Spacer()
                        nextPoint.padding(.trailing, 20)

                    }.padding(.bottom, 20)
                } //end selected item info and arrow buttons VStack
           } //end if hasMapPointsResults
        } //end VStack
        .onAppear(perform: {
                map.createScoringFileForTheDay(tripOrRouteName: tripOrRouteName) // NEED TO NOT CREATE IF NOT NEEDED?
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
//                map.resetScoreButtons()
                // clear score vars
            }
        }
        else {
            // offset should be 1
            if map.currentAnnoItem > 0 {
                map.currentAnnoItem -= 1
                highlightMapAnnotation(offset, offsetColor)
//                map.resetScoreButtons()
                // clear score vars
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
