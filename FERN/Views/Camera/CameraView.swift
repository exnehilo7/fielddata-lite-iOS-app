//
//  CameraView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/17/24.
//
//  17-JUN-2024: Replaces TripModeThoroughCameraView

import SwiftUI
import SwiftData

struct CameraView: View {
    
    var map: MapClass
    var gps: GpsClass
    @Bindable var camera: CameraClass
    var mapMode: String
    var tripOrRouteName: String
    @Bindable var measurements: MeasurementsClass
    var openedFromMapView: Bool = false
    
    // Swift Data
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    @Query var sdTrips: [SDTrip]
    
    // View toggles
//    @State private var isShowCamera = false
//    @State private var showingStoppedNMEAAlert = false
//    @State private var showingInvalidSyntaxAlert = false
//    @State private var showingHDOPOverLimit = false
//    @State private var showingCompleteAlert = false
    
    // Text scanning
    @State private var recognizedContent = RecognizedContent()
    @State private var isRecognizing = false
    
    // Image
    @State private var image = UIImage()
    
    // scoring
    @State private var isScoringActive = false
    @State private var showScoreTextField = false
    @State private var showMeasurementSelect = false
    //    @ObservedObject var measurements = Measurements()
    
    
    // Sounds
    let audio = playSound()
    
    // Core Location
    var clLat:String {
        return "\(gps.clLocationHelper?.lastLocation?.coordinate.latitude ?? 0.0000)"
    }
    var clLong:String {
        return "\(gps.clLocationHelper?.lastLocation?.coordinate.longitude ?? 0.0000)"
    }
    var clHorzAccuracy:String {
        return "\(gps.clLocationHelper?.lastLocation?.horizontalAccuracy ?? 0.00)"
    }
    var clVertAccuracy:String {
        return "\(gps.clLocationHelper?.lastLocation?.verticalAccuracy ?? 0.00)"
    }
    var clAltitude:String {
        return "\(gps.clLocationHelper?.lastLocation?.altitude ?? 0.0000)"
    }
    //------------------------------------------------------------------
    
    
    // MARK: Views
    // MARK: Text Fields
    // GPS Data Display ------------------------------------------------
    // Arrow Gold
    var arrowGpsData: some View {
        VStack {
            Label("EOS Arrow Gold", systemImage: "antenna.radiowaves.left.and.right").underline().foregroundColor(.yellow)
            // Text("Protocol: ") + Text(gps.nmea?.protocolText as String)
            Text("Latitude: ") + Text(gps.nmea?.latitude ?? "0.0000")
            Text("Longitude: ") + Text(gps.nmea?.longitude ?? "0.0000")
            Text("Altitude (m): ") + Text(gps.nmea?.altitude ?? "0.00")
            Text("Horizontal Accuracy (m): ") + Text(gps.nmea?.accuracy ?? "0.00").foregroundColor(getColor(text: gps.nmea?.accuracy ?? "0.00"))
            Text("GPS Used: ") + Text(gps.nmea?.gpsUsed ?? "No GPS")
        }.font(.system(size: 18))
    }
    
    // iOS Core Location
    var coreLocationGpsData: some View {
        VStack {
            Label("Standard GPS", systemImage: "location.fill").underline().foregroundColor(.blue)
            Text("Latitude: ") + Text("\(clLat)")
            Text("Longitude: ") + Text("\(clLong)")
            Text("Altitude (m): ") + Text("\(clAltitude)")
            Text("Horizontal Accuracy (m): ") + Text("\(clHorzAccuracy)").foregroundColor(getColor(text: clHorzAccuracy))
            Text("Vertical Accuracy (m): ") + Text("\(clVertAccuracy)")
        }.font(.system(size: 15))
            .padding()
    }
    
    // Snapshot Coords
    var snapshotCoordinates: some View {
        VStack {
            Label("Captured Coordinates", systemImage: "globe").underline().foregroundColor(.orange)
            Text("Latitude: ") + Text("\(camera.snapshotLatitude)").foregroundColor(snapshotColoring(text: camera.snapshotLatitude))
            Text("Longitude: ") + Text("\(camera.snapshotLongitude)").foregroundColor(snapshotColoring(text: camera.snapshotLongitude))
            Text("Altitude (m): ") + Text("\(camera.snapshotAltitude)").foregroundColor(snapshotColoring(text: camera.snapshotAltitude))
            Text("Horizontal Accuracy (m): ") + Text("\(camera.snapshotHorzAccuracy)").foregroundColor(getColor(text: camera.snapshotHorzAccuracy))
        }.font(.system(size: 18)).foregroundColor(.blue)
    }
    //------------------------------------------------------------------
    
    // Field for user to add custom metadata.
    var customData: some View {
        VStack {
            HStack {
                Text("Notes:")
                TextField("",
                          text: self.$camera.textNotes,
                          prompt: Text("Tap to add a note").foregroundColor(.green.opacity(0.75))
                ).textFieldStyle(.roundedBorder).autocapitalization(.none)//.foregroundColor(.green)
            }
        }
    }
    
    // MARK: Alerts
    // NMEA Alert
    var noStreamDataView: some View {
        VStack {
            Spacer()
            Text("Stream Has No Data").bold().foregroundStyle(.red)
            Text("Photo was not saved. The Bluetooth device could be attempting to reconnect, there could be issues with the satellite feed to the Bluetooth device or with the Bluetooth device itself. If the app needs to be stopped, swipe up from the bottom of the screen and pause 1/4 of the way up. Release, then swipe up on the app's preview.")
        }
    }
    
    // Invalid Syntax Alert
    var invalidSyntaxView: some View {
        VStack {
            Spacer()
            Text("Invalid Syntax").bold().foregroundStyle(.red)
            Text("The syntax for the Notes field is invalid!")
        }
    }
    
    // HDOP Over Threshold Alert
    var hdopOverLimitView: some View {
        VStack {
            Spacer()
            Text("HDOP Over Limit").bold().foregroundStyle(.red)
            Text("The horizontal position accuracy of \(camera.snapshotHorzAccuracy) was over the limit of \(settings[0].hdopThreshold)!")
        }
    }
    
    // streamWasLostMessage
    var streamWasLostMessage: some View {
        VStack {
            Text("BLUETOOTH END EVENT ENCOUNTERED").bold()
                .foregroundStyle(.white)
                .frame(minWidth: 95, maxWidth: 400, minHeight: 0, maxHeight: 50)
                .background(Color.red)
                .foregroundColor(.white)
                .padding(.horizontal)
            Text("Attempting to reconnect...")
        }
    }
    
    // MARK: Buttons
    // Show HDOP setting view button
    var showHdopSettingButton: some View {
        Button {
            camera.showHDOPSettingView = true
        }
        label: { HStack {Image(systemName: "arrow.up.to.line").font(.system(size: 10))}
                .frame(minWidth: 0, maxWidth: 25, minHeight: 0, maxHeight: 17)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(5).padding(.horizontal)
        }.popover(isPresented: $camera.showHDOPSettingView) {
            // Show view
            SettingsHdopView(setting: settings[0], camera: camera)  // NEED TO HIDE GPS OPTION ON VIEW POPUP (on dissapear?)
        }
    }
    
    // Save the pic button
    var savePicButton: some View {
        Button(action: {
            let fileNameUUID = UUID().uuidString
            let upperUUID = fileNameUUID.uppercased()
            var textInPic = recognizedContent.items[0].text
            textInPic = textInPic.replacingOccurrences(of: ScannedTextPattern().pattern, with: "", options: [.regularExpression])
            savePic(upperUUID: upperUUID, textInPic: textInPic, textNotes: camera.textNotes)
            // If score/measurement exists, write to score CSV
            
        }, label: {
            HStack {
                Image(systemName: "checkmark").font(.system(size: 20)) //"photo"  square.and.arrow.down
                Text("Done").font(.headline)
            }
            .frame(minWidth: 95, maxWidth: 100, minHeight: 0, maxHeight: 50)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(20)
            .padding(.horizontal)
        })
    }
    
    // Show camera button
    var showCameraButton: some View {
        Button {
            camera.isShowCamera = true
            camera.showingNoStreamDataAlert = false
        } label: {
            Label("Show Camera", systemImage: "camera").foregroundColor(.white)
        }.buttonStyle(.borderedProminent).tint(.blue)
    }
    
    // Scan for text button
    var scanForTextButton: some View {
        Button(action: {
            
            isRecognizing = true
            
            // Put image in array
            var imageArray = [UIImage]()
            imageArray.append(camera.image)
            
            // Call struct
            TextRecognition(scannedImages: imageArray,
                            recognizedContent: recognizedContent) {
                // Text recognition is finished, hide the progress indicator.
                isRecognizing = false
            }.recognizeText()
        }, label: {
            HStack {
                Image(systemName: "text.viewfinder").font(.system(size: 20))
                Text("Scan")//.font(.headline)
            }
            .frame(minWidth: 95, maxWidth: 100, minHeight: 0, maxHeight: 50)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(20)
            .padding(.horizontal)
        })
    }
    
    // Cancel pic button
    var cancelPicButton: some View {
        Button(action: {
            camera.cancelPic()
        },
               label: {HStack {
            Image(systemName: "arrow.triangle.2.circlepath.camera").font(.system(size: 15))
            Text("Redo").font(.system(size: 15))
        }
               .frame(minWidth: 0, maxWidth: 75, minHeight: 0, maxHeight: 30)
               .background(Color.red)
               .foregroundColor(.white)
               .cornerRadius(10)
               .padding().padding()
        })
    }
    
    // Restart Arrow button
    var restartArrowViaStartNMEAButton: some View {
        Button(action: {
                gps.restartArrowViaStartNMEA()
        },
               label: {HStack {
            Image(systemName: "arrow.circlepath").font(.system(size: 15))
            Text("Restart Arrow").font(.system(size: 15))
        }
               .frame(minWidth: 95, maxWidth: 100, minHeight: 0, maxHeight: 50)
               .background(Color.green)
               .foregroundColor(.white)
               .cornerRadius(10)
               .padding().padding()
        })
    }
    var startArrowButton: some View {
        Button(action: {
            Task.detached {
                await gps.startGPSFeed(settings: settings)
            }
        },
               label: {HStack {
            Image(systemName: "arrow.circlepath").font(.system(size: 15))
            Text("Start Arrow as if app first opened").font(.system(size: 15))
        }
               .frame(minWidth: 95, maxWidth: 100, minHeight: 0, maxHeight: 50)
               .background(Color.blue)
               .foregroundColor(.white)
               .cornerRadius(10)
               .padding().padding()
        })
    }
    
    // Swipe down chevron
    var swipeDownChevron: some View {
        Image(systemName: "chevron.compact.down").bold(false).foregroundColor(.white).font(.system(size:32))
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
//            .padding(.horizontal)
        }
    }
    
    // Previous Item
    var previousItem: some View {
        // backward
        Button(action: {
            withAnimation {
                if isScoringActive {
                    measurements.cycleScoringTypes(forward: false)
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
                }
            }
        }, label: {
            VStack {
                Image(systemName: "arrowshape.forward.fill")
                    .font(.system(size: 50))
            }
        })
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
    
    
    // MARK: Main View
    var body: some View {
        VStack {
            if openedFromMapView {
                swipeDownChevron
            }
            
            if !camera.isImageSelected {
                // mark complete button
                ForEach(sdTrips) { item in
                    // Get the previous view's selected trip
                    if (item.name == tripOrRouteName){
                        Button {
                            camera.showCompleteAlertToggle()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.square")
                                    .font(.system(size: 20))
                                Text("Mark Trip Complete")
                                    .font(.headline)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .padding(.horizontal)
                        }.alert("Mark trip as complete?", isPresented: $camera.showingCompleteAlert) {
                            Button("OK"){
                                item.isComplete = true
                                camera.showCompleteAlertToggle()
                            }
                            Button("Cancel", role: .cancel){}
                        } message: {
                            Text("""
            
            Once completed, additional pictures cannot be added to the trip.
            
            THIS CANNOT BE REVERSED.
            
            Do you wish to continue?
            """)
                        }
                    }
                }
                Spacer()
            }
            // No-NMEA alert
            if camera.showingNoStreamDataAlert {
                noStreamDataView
            }
            
            if camera.showingInvalidSyntaxAlert {
                invalidSyntaxView
            }
            
            if camera.showingHDOPOverLimit {
                hdopOverLimitView
            }
            
            
            // Show the pic to be saved
            Image(uiImage: camera.image)
                .resizable()
                .scaledToFit()
            
            // Custom notes
            if !showScoreTextField {
                if camera.isImageSelected {
                    customData.transition(.scale.combined(with: .opacity))
                }
            }
            
            Spacer()
            
            // Give the user an option to bring back the camera if the ImagePicker was cancelled.
            // Don't show if an image is ready to save
            if !camera.isImageSelected {
                // Don't show if the camera is already showing
                if !camera.isShowCamera {
                    showCameraButton
                }
            }
            
            // Don't display GPS coords if camera sheet is displayed.
            if !showScoreTextField {
                if !camera.isShowCamera {
                    snapshotCoordinates
                }
            }
            
            // Scoring view
            if showScoreTextField {
                measurementsAndNumberpad.transition(.scale.combined(with: .opacity))
            }
            
            // Display recognized text
            if !showScoreTextField {
                if isRecognizing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor.systemIndigo)))
                        .padding(.bottom, 20)
                } else {
                    if recognizedContent.items[0].text != ""{
                        HStack {
                            Text("Scanned text: ")
                            TextPreviewView(scannedText: recognizedContent.items[0].text).transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            
            // Cancel button
            if !showScoreTextField {
                if camera.isImageSelected {
                    HStack {
                        cancelPicButton.transition(.move(edge: .bottom))
                    }
                }
            }
            
            HStack {
                
                // Show the image save button if ImagePicker struct has an image.
                if camera.isImageSelected {
                    if !showScoreTextField {
                        scanForTextButton.transition(.scale.combined(with: .opacity))
                    } else {
                        previousItem.transition(.scale.combined(with: .opacity))
                    }
                    
                    if !openedFromMapView {
                        scoringButton
                    } else { Spacer()}

                    if !showScoreTextField {
                        savePicButton.transition(.scale.combined(with: .opacity))
                    } else {
                        nextItem.transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }.onAppear(perform: {
            // Create Image Metadata file
            camera.createImageCsvFileForTheDay(tripOrRouteName: tripOrRouteName)
            
            // Create Scoring file
            map.createScoringFileForTheDay(tripOrRouteName: tripOrRouteName)
            
            // Clear snapshot GPS vals
            camera.resetSnaphotCords()
            
        })
        
        .sheet(isPresented: $camera.isShowCamera) {
            // Show the GPS data at all times on the bottom half of the screen
            ZStack {
                Color.black.ignoresSafeArea(.all)
                VStack {
                    ImagePicker(sourceType: .camera, selectedImage: $camera.image, imageIsSelected: $camera.isImageSelected)
                    // GPS data on sheet
                    if settings[0].useBluetoothDevice {
                        HStack {
                            if gps.nmea?.endEventEncountered ?? false {
                                streamWasLostMessage
                                restartArrowViaStartNMEAButton
                            } else {
                                arrowGpsData
    //                            VStack {
    //                                startArrowButton
    //                                restartArrowViaStartNMEAButton
    //                            }
                            }
                        }
                    }
                    else {
                        coreLocationGpsData
                    }
                    // Snapshot GPS data on dissappear
                }.onDisappear {
                    if settings[0].useBluetoothDevice {
                        camera.snapshotLatitude = gps.nmea?.latitude ?? "0.00000000"
                        camera.snapshotLongitude = gps.nmea?.longitude ?? "0.00000000"
                        camera.snapshotAltitude = gps.nmea?.altitude ?? "0.00"
                        camera.snapshotHorzAccuracy = gps.nmea?.accuracy ?? "0.00"
                    }
                    else {
                        camera.snapshotLatitude = clLat
                        camera.snapshotLongitude = clLong
                        camera.snapshotAltitude = clAltitude
                        camera.snapshotHorzAccuracy = clHorzAccuracy
                    }
                }
            }
        }.animation(.easeInOut, value: true)
            .preferredColorScheme(.dark)
    }
    
    // MARK: Functions
    private func savePic(upperUUID: String, textInPic: String, textNotes: String) {
        
        let result = camera.checkUserData(textNotes: textNotes)
        
        var long: String
        var lat: String
        var organismName: String
        
        // if user data is all good, save pic
        if result.isValid {
            
            var imageSuccessful = false
            
            // Bluetooth?
            if settings[0].useBluetoothDevice {
                imageSuccessful = camera.processImage(useBluetooth: settings[0].useBluetoothDevice, btStreamHasNoData: gps.nmea?.streamHasNoData ?? false, btEndEventHasNoData: gps.nmea?.endEventEncountered ?? false, hdopThreshold: settings[0].hdopThreshold, imgFile: image, tripOrRouteName: tripOrRouteName, uuid: upperUUID, gpsUsed: "ArrowGold", scannedText: textInPic, notes: result.textNotes)
            } else {
                imageSuccessful = camera.processImage(useBluetooth: settings[0].useBluetoothDevice, btStreamHasNoData: true, btEndEventHasNoData: true, hdopThreshold: settings[0].hdopThreshold, imgFile: image, tripOrRouteName: tripOrRouteName, uuid: upperUUID, gpsUsed: "iOS", scannedText: textInPic, notes: result.textNotes)
            }
            
            long = camera.snapshotLongitude
            lat = camera.snapshotLatitude
            organismName = textInPic
            
            // pop view back down
            if imageSuccessful && mapMode != "none"{
                map.showPopover = false
            }
            
            // If image save and file write was successful, and map mode is Route, change annotation's color to blue:
            if imageSuccessful && mapMode == "Traveling Salesman" {
                Task {
                    await map.updatePointColor(settings: settings, phpFile: "updateRoutePointColor.php",
                                               postString:"_route_id=\(map.annotationItems[map.currentAnnoItem].routeID)&_point_order=\(map.annotationItems[map.currentAnnoItem].pointOrder)")
                }
            }
            
            // If image save and file write was successful, (and mapMode is "View Trip"?), add a temp point to the map
            if imageSuccessful {
                map.tempMapPoints.append(MapAnnotationItem(
                    latitude: Double(lat) ?? 0,
                    longitude: Double(long) ?? 0,
                    routeID: "0",
                    pointOrder: "0",
                    organismName: organismName,
                    systemName: "mappin",
                    size: 20,
                    highlightColor: Color (
                        red: 1,
                        green: 0.35,
                        blue: 0
                    )
                ))
            }
            
            // Clear displayed image
            camera.image = UIImage()
            // Clear scanned text
            recognizedContent.items[0].text = ""
            
            // Clear custom data
            camera.clearCustomData()
            
            // If image save was successful, Write scores to file, clear scores / measurements
            if imageSuccessful {
                // Put scores into JSON format, write to CSV
                let scoresJSON = measurements.createScoreJSON()
                camera.saveScoreToTextFile(tripOrRouteName: tripOrRouteName, fileNameUUID: upperUUID, longitude: camera.snapshotLongitude, latitude: camera.snapshotLatitude, organismName: upperUUID, score: scoresJSON)
                measurements.clearMeasurementVars()
            }
            
        } else {
            audio.playError()
            camera.showingInvalidSyntaxAlert = true
        }
    }
    
    // Get a color based on HDOP threshold
    func getColor(text: String) -> Color {
        
        guard let threshold = Double(text) else { return Color.white }
        
        if threshold > settings[0].hdopThreshold {
            return Color.red
        } else if threshold <= settings[0].hdopThreshold {
            return Color.green
        }
        return Color.white
    }
    
    // If value is 0, color red
    func snapshotColoring(text: String) -> Color {
        
        guard let value = Double(text) else { return Color.blue }
        
        if value == 0 {
            return Color.red
        }
        
        return Color.blue
    }
}
