//
//  MapView.swift
//  FERN
//
//  Created by Hopp, Dan on 3/7/24.
//  Map basics help from https://www.mongodb.com/developer/products/realm/realm-swiftui-maps-location/
//  User can choose default GPS or Arrow Gold GPS. If Arrow is selected, use a custom current device position icon(?)
//
//  05-JUN-2024: See if this view can be for Routes (traveling salesman) only, and if the slow camera view code can be added here and its view integrated with this one. Will need to append current point's organism name into the custom data field. (Populate the custom data field on pic snap? "Organism name: XXXXXXXXX;"?)
//  Hide Reset Route Markers?

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
    @Query var sdTrips: [SDTrip]
    
    // From calling view
    var tripName: String
    var columnName: String
    var organismName: String
    var queryName: String
    
    // Annotation tracking
    @State private var currentAnnoItem = 0 // starting index is 0, so the first "next" will be 1
    @State private var totalAnnoItems = 0
    
    // For map points PHP response
    @State private var mapResults: [TempMapPointModel] = []
    @State private var hasMapPointsResults = false
    
//    //Distance and bearing PHP response
//    @State private var distanceAndBearingResult: [TempDistanceAndBearingModel] = []
//    @State private var hasDistanceAndBearingResult = false
//    @State private var distance = "0"
//    @State private var bearing = "0"
    
//    // Start and end lat and longs
//    @State private var startLong = "0"
//    @State private var startLat = "0"
//    @State private var startLongFloat = 0.0
//    @State private var startLatFloat = 0.0
//    @State private var endLongFloat = 0.0
//    @State private var endLatFloat = 0.0
    
    // Show take pic button and popover view
    @State private var showPicButton = false
    @State private var showPopover = false
    
    // Sounds
    let audio = playSound()
    
    // To hold Annotated Map Point Models
    @State private var annotationItems = [MapAnnotationItem]()
    
    // To hold the starting region's coordinates and zoom level
//    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    // For 17.0's MapKit SDK change
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    )
    // For map reloads
    @State private var currentCameraPosition: MapCameraPosition?
    
    
    // Alerts
    @State private var showAlert = false
    @State private var article = Article(title: "Device Feed Error", description: "Check the Bluetooth or satellite connection. If both are OK, try killing and restarting the app.")
    
    // User GPS selection
    @State var gpsModeIsSelected = false
    @State var showArrowGold = false
//    var showArrowGold:Bool
//    var gpsModeIsSelected:Bool
    

    // From TripModeThoroughCameraView's code
    @State private var isShowCamera = false
    @ObservedObject var recognizedContent = RecognizedContent()
    @State private var isRecognizing = false
    @State private var isImageSelected = false
    @State private var image = UIImage()
    @State private var showingStoppedNMEAAlert = false
    @State private var showingInvalidSyntaxAlert = false
    @State private var textNotes = ""
    @State private var scrubbedNotes = ""
    @State private var numofmatches = 0
    @State private var showingCompleteAlert = false
    
    
    //MARK: Sections from View's Original Setup
    // GPS -------------------------------------------------------------
    // Arrow Gold
    @ObservedObject var nmea:NMEA = NMEA()
//    @EnvironmentObject var nmea:NMEA
    
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
    
    
//    // GPS Data Display ------------------------------------------------
//    // Arrow Gold
//    var arrowGpsData: some View {
//        VStack {
//            Label("EOS Arrow Gold", systemImage: "antenna.radiowaves.left.and.right").underline()
//            HStack {
//                Text("Lat: ") + Text(nmea.latitude ?? "0.0000")
//                Text("Long: ") + Text(nmea.longitude ?? "0.0000")
//            }
//            HStack {
//                Text("Alt (m): ") + Text(nmea.altitude ?? "0.00")
//                Text("Horz Acc (m): ") + Text(nmea.accuracy ?? "0.00")
//            }
//            HStack {
//                Text("GPS Used: ") + Text(nmea.gpsUsed ?? "No GPS")
//            }
//        }.font(.system(size: 12))//.foregroundColor(.white)
//    }
//    
//    // iOS Core Location
//    var coreLocationGpsData: some View {
//        VStack {
//            Label("Standard GPS",  systemImage: "location.fill").underline()
//            HStack {
//                Text("Lat: ") + Text("\(clLat)")
//                Text("Long: ") + Text("\(clLong)")
//            }
//            
//                Text("Alt (m): ") + Text("\(clAltitude)")
//            HStack {
//                Text("Horz Acc (m): ") + Text("\(clHorzAccuracy)")
//                Text("Vert Acc (m): ") + Text("\(clVertAccuracy)")
//            }
//        }.font(.system(size: 12))//.foregroundColor(.white)
//    }
//    //------------------------------------------------------------------
//    
//    // Select GPS mode
//    var selectGpsMode: some View {
//        HStack {
//            HStack{
//                Button{
//                    gpsModeIsSelected = true
//                    // To prevent the device feed from being interruped, disable autosleep
//                    UIApplication.shared.isIdleTimerDisabled = true
//                    
//                    // Convert strings to floats for rounding and comaprisons
//                    startLongFloat = (clLong as NSString).doubleValue
//                    startLatFloat = (clLat as NSString).doubleValue
//                    endLongFloat = annotationItems[currentAnnoItem].longitude
//                    endLatFloat = annotationItems[currentAnnoItem].latitude
//                    // Round at 6 decimals
//                    startLongFloat = round(100000 * startLongFloat) / 100000
//                    startLatFloat = round(100000 * startLatFloat) / 100000
//                    endLongFloat = round(100000 * endLongFloat) / 100000
//                    endLatFloat = round(100000 * endLongFloat) / 100000
//                } label: {
//                    Label("Use Standard GPS", systemImage: "location.fill")
//                }.buttonStyle(.borderedProminent)
//            }.padding(.leading, 20)
//            Spacer()
//            HStack{
//                Button{
//                    showArrowGold = true
//                    // basic core off
//                    clLocationHelper.stopUpdatingDefaultCoreLocation()
//                    nmea.viewDidLoad()
//                    gpsModeIsSelected = true
//                    // To prevent the device feed from being interruped, disable autosleep
//                    UIApplication.shared.isIdleTimerDisabled = true
//                    
//                    // Convert strings to floats for rounding and comaprisons
//                    startLongFloat = ((nmea.longitude ?? "0.0000") as NSString).doubleValue
//                    startLatFloat = ((nmea.latitude ?? "0.0000") as NSString).doubleValue
//                    endLongFloat = annotationItems[currentAnnoItem].longitude
//                    endLatFloat = annotationItems[currentAnnoItem].latitude
//                    // Round at 6 decimals
//                    startLongFloat = round(100000 * startLongFloat) / 100000
//                    startLatFloat = round(100000 * startLatFloat) / 100000
//                    endLongFloat = round(100000 * endLongFloat) / 100000
//                    endLatFloat = round(100000 * endLongFloat) / 100000
//                } label: {
//                    Label("Use Arrow Gold Device", systemImage: "antenna.radiowaves.left.and.right").foregroundColor(.black)
//                }.buttonStyle(.borderedProminent).tint(.yellow)
//            }.padding(.trailing, 20)
//        // (THIS SHOULD CHECK CONSTANTLY?)
//        }.onAppear(perform: {
//            showPicButton = true
//            // if start lat long = end lat long, let user take pic.
//            //if (startLongFloat == endLongFloat && startLatFloat == endLatFloat) {showPicButton = true} //; audio.playDing()}
//        })
//    }
//    
//    // Where is next? button
//    var whereIsNext: some View {
//        Button {
//            Task {
//                // Get starting lat and long
////                if showArrowGold {
////                    startLong = nmea.longitude ?? "0.0000"
////                    startLat = nmea.latitude ?? "0.0000"
////                }
////                else {
////                    startLong = clLong
////                    startLat = clLat
////                }
////                
////                // if not default values, call
////                if (startLong != "0.0000" && startLat != "0.0000"){
////                    await getDistanceAndBearing()
////                }
//                
//                // JUST IN CASE THE CHECK IS NOT AUTO:
//                // if start lat long = end lat long, let user take pic.
//                //if (startLongFloat == endLongFloat && startLatFloat == endLatFloat) {showPicButton = true} //; audio.playDing()}
//            }
//        } label: {
//            VStack{
////                // Flip text based on result
////                if !hasDistanceAndBearingResult {
////                    Text("Point to next")
////                }
////                if hasDistanceAndBearingResult {
////                    Text("\(bearing)°; \(distance)(m)")
////                }
//            }
//        }.buttonStyle(.borderedProminent).tint(.green).padding(.bottom, 25).font(.system(size:15))
//    }
    
    //MARK: View code from TripModeThoroughCameraView
    // GPS Data Display ------------------------------------------------
    // Arrow Gold
    var arrowGpsData: some View {
        VStack {
            
            Label("EOS Arrow Gold", systemImage: "antenna.radiowaves.left.and.right").underline()
            //            Text("Protocol: ") + Text(nmea.protocolText as String)
            Text("Latitude: ") + Text(nmea.latitude ?? "0.0000")
            Text("Longitude: ") + Text(nmea.longitude ?? "0.0000")
            Text("Altitude (m): ") + Text(nmea.altitude ?? "0.00")
            Text("Horizontal Accuracy (m): ") + Text(nmea.accuracy ?? "0.00")
            Text("GPS Used: ") + Text(nmea.gpsUsed ?? "No GPS")
        }.font(.system(size: 18))//.foregroundColor(.white)
    }
    
    // iOS Core Location
    var coreLocationGpsData: some View {
        VStack {
            
            Label("Standard GPS",  systemImage: "location.fill").underline()
            Text("Latitude: ") + Text("\(clLat)")
            Text("Longitude: ") + Text("\(clLong)")
            Text("Altitude (m): ") + Text("\(clAltitude)")
            Text("Horizontal Accuracy (m): ") + Text("\(clHorzAccuracy)")
            Text("Vertical Accuracy (m): ") + Text("\(clVertAccuracy)")
        }.font(.system(size: 15))//.foregroundColor(.white)
            .padding()
    }
    //------------------------------------------------------------------
    
    // Select GPS mode
    var selectGpsMode: some View {
        HStack {
            HStack{
                Button{
                    gpsModeIsSelected = true
                    createTxtFileForTheDay()
                    UIApplication.shared.isIdleTimerDisabled = true
                    isShowCamera = true
                    // Clear scanned text
                    recognizedContent.items[0].text = ""
                } label: {
                    Label("Use Standard GPS", systemImage: "location.fill")
                }.buttonStyle(.borderedProminent)
            }.padding(.leading, 20)
            Spacer()
            HStack{
                Button{
                    showArrowGold = true
                    clLocationHelper.stopUpdatingDefaultCoreLocation() // basic core off
                    nmea.viewDidLoad()
                    gpsModeIsSelected = true
                    createTxtFileForTheDay()
                    UIApplication.shared.isIdleTimerDisabled = true
                    isShowCamera = true
                    // Clear scanned text
                    recognizedContent.items[0].text = ""
                } label: {
                    Label("Use Arrow Gold Device", systemImage: "antenna.radiowaves.left.and.right").foregroundColor(.black)
                }.buttonStyle(.borderedProminent).tint(.yellow)
            }.padding(.trailing, 20)
        }
    }
    
    // NMEA Alert
    var stoppedNMEA: some View {
        VStack {
            Spacer()
            Text("Device Feed Error").bold().foregroundStyle(.red)
            Text("Photo was not saved. Check the Bluetooth or satellite connection. If both are OK, try killing and restarting the app.")
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
    
    // Save the pic button
    var savePicButton: some View {
        Button(action: {
            let audio = playSound()
            let fileNameUUID = UUID().uuidString
            let upperUUID = fileNameUUID.uppercased()
            var textInPic = recognizedContent.items[0].text
            textInPic = textInPic.replacingOccurrences(of: ScannedTextPattern().pattern, with: "", options: [.regularExpression])
            // if user data is all good, save pic
            if checkUserData() {
                    if showArrowGold {
                        // Alert user if feed has stopped or values are zero
                        if nmea.hasNMEAStreamStopped ||
                            ((nmea.accuracy ?? "0.00") == "0.00" || (nmea.longitude ?? "0.00000000") == "0.00000000" ||
                             (nmea.latitude ?? "0.00") == "0.00000000" || (nmea.altitude ?? "0.00") == "0.00")
                        {
                            // GPS coords are set to 0 in NMEADataClass
                            // For whatever reason, the button's .alert stopped working. Switch to stoppedNMEA view toggle instead.
//                            article.title = "Device Feed Error"
//                            article.description = "Photo was not saved. Check the Bluetooth or satellite connection. If both are OK, try killing and restarting the app."
//                            showAlert = true
                            audio.playError()
                            isImageSelected = false
                            showingStoppedNMEAAlert = true
                        } else {
                            // Pass Arrow GPS data
                            savePicToFolder(imgFile: image, tripName: tripName, uuid: upperUUID, gps: "ArrowGold",
                                            hdop: nmea.accuracy ?? "0.00", longitude: nmea.longitude ?? "0.0000", latitude: nmea.latitude ?? "0.0000", altitude: nmea.altitude ?? "0.00",
                                            scannedText: textInPic, notes: textNotes)
                            isImageSelected = false
                            isShowCamera = true
                            showingInvalidSyntaxAlert = false
                            // Change annotation's color to blue
                            Task {
                                await updatePointColor(routeID: annotationItems[currentAnnoItem].routeID,
                                                       pointOrder: annotationItems[currentAnnoItem].pointOrder)
                            }
                            
                            // pop view back down
                            showPopover = false
                            
//                            // Mark currently seleted point as "done"
//                            annotationItems[currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
                        }
                    } else {
                        // Pass default GPS data
                        savePicToFolder(imgFile: image, tripName: tripName, uuid: upperUUID, gps: "iOS",
                                        hdop: clHorzAccuracy, longitude: clLong, latitude: clLat, altitude: clAltitude,
                                        scannedText: textInPic, notes: textNotes)
                        isImageSelected = false
                        isShowCamera = true
                        showingInvalidSyntaxAlert = false
                        // Change annotation's color to blue
                        Task {
                            await updatePointColor(routeID: annotationItems[currentAnnoItem].routeID,
                                                   pointOrder: annotationItems[currentAnnoItem].pointOrder)
                        }
            
                        // pop view back down
                        showPopover = false
                        
//                        // Mark currently seleted point as "done"
//                        annotationItems[currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
                    }
                    
                    // Clear displayed image (if previous image feedback is needed, borrow capturedPhotoThumbnail from CameraView?
                    self.image = UIImage()
                    // Clear scanned text
                    recognizedContent.items[0].text = ""
                    // Clear custom data
                    clearCustomData()
            } else {
                audio.playError()
//                invalidSyntax("for the Notes field")
                showingInvalidSyntaxAlert = true
//                showAlert = true
            }// end user notes check
        }, label: {
            HStack {
                Image(systemName: "photo")
                    .font(.system(size: 20))//.foregroundColor(.green)
                
                Text("Save Image")
                    .font(.headline)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(20)
            .padding(.horizontal)
        })
//        .alert(article.title, isPresented: $showAlert, presenting: article) {article in Button("OK"){showAlert = false
//        }} message: {article in Text(article.description)}
    }
    
    // Show the camera button (for if the user cancels a photo)
    var showCameraButton: some View {
        Button {
            isShowCamera = true
            showingStoppedNMEAAlert = false
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
            imageArray.append(self.image)
            
            // Call struct
            TextRecognition(scannedImages: imageArray,
                            recognizedContent: recognizedContent) {
                // Text recognition is finished, hide the progress indicator.
                isRecognizing = false
            }
                            .recognizeText(
                            )
        }, label: {
            HStack {
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 20))//.foregroundColor(.green)
                
                Text("Scan Text")
                    .font(.headline)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(20)
            .padding(.horizontal)
        })
    }
    
    var cancelPicButton: some View {
        Button(action: {cancelPic()},
        label: {HStack {
            Image(systemName: "nosign").font(.system(size: 10))
            Text("Cancel").font(.system(size: 10))
        }
            .frame(minWidth: 0, maxWidth: 62, minHeight: 0, maxHeight: 25)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(20)
            .padding(.horizontal)
        })
    }
    
    // Fields for user to add custom metadata. Will need to create @State private var's
    var customData: some View {
        VStack {
            HStack {
                Text("Notes:")//.foregroundColor(.white)
                TextField("",
                          text: $textNotes,
                          prompt: Text("branch count: 42; status: alive;").foregroundColor(.green.opacity(0.5))
                ).textFieldStyle(.roundedBorder).autocapitalization(.none).foregroundColor(.yellow)
            }
        }
    }
    
    // View for Camera
    var popUpThoroughCamera: some View {
        VStack {
            if !isImageSelected {
                // mark complete button
                ForEach(sdTrips) { item in
                    // Get the previous view's selected trip
                    if (item.name == tripName){
                        Button {
                            showCompleteAlertToggle()
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
                        }.alert("Mark trip as complete?", isPresented: $showingCompleteAlert) {
                            Button("OK"){
                                item.isComplete = true
                                showCompleteAlertToggle()
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
            if showingStoppedNMEAAlert {
                stoppedNMEA
            }
            
            if showingInvalidSyntaxAlert {
                invalidSyntaxView
            }
            
            
            
            // Show the pic to be saved
            Image(uiImage: self.image)
                .resizable()
                .scaledToFit()
            
            if isImageSelected {
                customData
            }
            
            Spacer()
            
            // Give the user an option to bring back the camera if the ImagePicker was cancelled.
            if gpsModeIsSelected {
                // Don't show if an image is ready to save
                if !isImageSelected {
                    // Don't show if the camera is already showing
                    if !isShowCamera {
                        showCameraButton
                    }
                }
            }
            
            // Show GPS feed if one was selected
            if gpsModeIsSelected {
                // Don't display GPS coords if sheet is displayed.
                if !isShowCamera {
                    if showArrowGold {
                        arrowGpsData
                    }
                    else {
                        coreLocationGpsData
                    }
                }
                
                // Display recognized text (remove list?)
                if isRecognizing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor.systemIndigo)))
                        .padding(.bottom, 20)
                } else {
                    if recognizedContent.items[0].text != ""{
                        HStack {
                            Text("Scanned text: ")
                            TextPreviewView(scannedText: recognizedContent.items[0].text)
                            
                        }
                    }
                }
                
                if isImageSelected {
                    HStack{
                        cancelPicButton
                    }
                }
                
                HStack {
                    
                    // Show the image save button if ImagePicker struct has an image.
                    if isImageSelected {
                        HStack {
                            scanForTextButton
                        }
                        Spacer()
                        HStack {
                            savePicButton
                        }
                    }
                }
            } else {
                selectGpsMode
            }
        }.sheet(isPresented: $isShowCamera) {
            // Try to show the GPS data at all times on the bottom half of the screen
            ZStack {
                Color.black.ignoresSafeArea(.all)
                VStack {
                    ImagePicker(sourceType: .camera, selectedImage: self.$image, imageIsSelected: self.$isImageSelected)//.presentationDetents([.fraction(0.6)])
                    // GPS data on sheet
                    if gpsModeIsSelected {
                        if showArrowGold {
                            arrowGpsData
                        }
                        else {
                            coreLocationGpsData
                        }
                    }
                }
            }
        }.animation(.easeInOut, value: true)
            .preferredColorScheme(.dark)
    } // end popUpThoroughCamera view
    
    
    //MARK: Show camera
    // Take pic button. Use a swipe-up view.
    var popupCameraButton: some View {
        Button {
//            showPicButton = false
            showPopover = true
            textNotes = "Organism name:" + annotationItems[currentAnnoItem].organismName + ";"
        } label: {
            Text("Show Camera")
        }.buttonStyle(.borderedProminent).tint(.orange).popover(isPresented: $showPopover) {

            popUpThoroughCamera
            
            // Old code from environmentObject experiment:
            // For the QC Map View, make a custom slider view using the fast(?) slow(?) choice(?) CameraView code in this file:
//            CameraImageView(mapViewIsActive: true, tripName: tripName, showArrowGold: showArrowGold, gpsModeIsSelected: gpsModeIsSelected)//.environmentObject(nmea)
        }
    }
    
    
    // MARK: Body
    var body: some View {
        
       // ZStack(alignment: .center) {
            VStack{
                // Reset map button
//                HStack {
//                    Spacer()
//                    Button ("Reset Route Markers"){
//                        Task {
//                            await resetRouteMarkers()
//                        }
//                    }.padding(.trailing, 25)
//                }
                // Show device's current position if GPS method is selected
                if gpsModeIsSelected {
                    // Have a "camera pop up" button?
                    popupCameraButton
                    
                        // show take pic button (or activate swipe-up) if start lat long = dest lat long
    //                    if !showPicButton {
                    
//                    if showArrowGold {
//                        arrowGpsData
//                    }
//                    else {
//                        coreLocationGpsData
//                    }
                    
    //                    } else {
//                    popupCameraButton
    //                    }
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
                    // For 17.0's new MapKit SDK
                    Map(position: $cameraPosition) {
                        UserAnnotation()
                        ForEach(annotationItems) { item in
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
            if hasMapPointsResults {
               VStack {
                   // Show organism name of the selected point
                   Text("Current Point:").font(.system(size:15))//.underline()
                   Text(annotationItems[currentAnnoItem].organismName).font(.system(size:20)).fontWeight(.bold)
                        // Mark first point on map
                       .onAppear(perform: {
                           annotationItems[currentAnnoItem].size = 20
                           // If currentAnnoItem is blue, make it light blue. Else make it red
                           if annotationItems[currentAnnoItem].highlightColor == Color(red: 0, green: 0, blue: 1) {
                               annotationItems[currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
                           } else {
                               annotationItems[currentAnnoItem].highlightColor = Color(red: 1, green: 0, blue: 0)
                           }
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
//                           // refresh map?
//                           Task {
//                               await refreshMap()
//                           }
                           cycleAnnotations(forward: false, 1)
                           // hide distance and bearing
//                           hasDistanceAndBearingResult = false
                           // Alert user if Arrow feed has stopped or values are zero
//                           if showArrowGold {
//                               checkActiveNMEAStream()
//                           }
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
//                           // refresh map?
//                           Task {
//                               await refreshMap()
//                           }
                           cycleAnnotations(forward: true, -1)
                           // hide distance and bearing
//                           hasDistanceAndBearingResult = false
                           // Alert user if Arrow feed has stopped or values are zero
//                           if showArrowGold {
//                               checkActiveNMEAStream()
//                           }
                       }, label: {
                           VStack {
                               Image(systemName: "arrowshape.forward.fill")
                                   .font(.system(size: 50))
                               Text("Next")
                           }
                       }).padding(.leading, 20)
                           .alert(article.title, isPresented: $showAlert, presenting: article) {article in Button("OK"){showAlert = false}} message: {article in Text(article.description)}
                       
                       // Where is next? button
                       // whereIsNext
                   }.padding(.bottom, 20)
               } // end vstack
           } // end if hasMapPointsResults
        }
//            .onAppear(perform: {
//            if showArrowGold {
//                // basic core off. May need to better handle LocationHelper instantiation
//                clLocationHelper.stopUpdatingDefaultCoreLocation()
//                
//                // NEED TO FIND A BETTER METHOD TO HANDLE START AND END POINTS FOR NAVIGATION GUIDANCE
//                
////                // Convert strings to floats for rounding and comaprisons
////                startLongFloat = ((nmea.longitude ?? "0.0000") as NSString).doubleValue
////                startLatFloat = ((nmea.latitude ?? "0.0000") as NSString).doubleValue
////                endLongFloat = annotationItems[currentAnnoItem].longitude
////                endLatFloat = annotationItems[currentAnnoItem].latitude
//            } else {
////                // Convert strings to floats for rounding and comaprisons
////                startLongFloat = (clLong as NSString).doubleValue
////                startLatFloat = (clLat as NSString).doubleValue
////                endLongFloat = annotationItems[currentAnnoItem].longitude
////                endLatFloat = annotationItems[currentAnnoItem].latitude
//            }
//            // To prevent the device feed from being interruped, disable autosleep
//            UIApplication.shared.isIdleTimerDisabled = true
////            // Round at 6 decimals
////            startLongFloat = round(100000 * startLongFloat) / 100000
////            startLatFloat = round(100000 * startLatFloat) / 100000
////            endLongFloat = round(100000 * endLongFloat) / 100000
////            endLatFloat = round(100000 * endLongFloat) / 100000
//            // Show pic button
//            showPicButton = true
//        })
    } //end body view
    
    
    // MARK: Functions
    private func createTxtFileForTheDay() {
        do{
            // create new txt file for the day for GPS data.
            _ = try FieldWorkGPSFile.log(tripName: tripName, uuid: "", gps: "", hdop: "", longitude: "", latitude: "", altitude: "", scannedText: "", notes: "")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func savePicToFolder(imgFile: UIImage, tripName: String, uuid: String, gps: String,
                                 hdop: String, longitude: String, latitude: String, altitude: String,
                                 scannedText: String, notes: String) {
        
        let audio = playSound()
        
        do{
            // Save image to Trip's folder
            try _ = FieldWorkImageFile.saveToFolder(imgFile: imgFile, tripName: tripName, uuid: uuid, gps: gps, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude)
        } catch {
            print(error.localizedDescription)
            audio.playError()
        }
        
        // Write the pic's info to a .txt file
        do {
            // .txt file header order is uuid, gps, hdop, longitude, latitude, altitude.
            try _ = FieldWorkGPSFile.log(tripName: tripName, uuid: uuid, gps: gps, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude, scannedText: scannedText, notes: notes)
            // Play a success noise
            audio.playSuccess()
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            print(error.localizedDescription)
            audio.playError()
        }
    }
    
    private func resetRouteMarkers() async {
        // remember current map camera position
        currentCameraPosition = cameraPosition
        hasMapPointsResults = false
        currentAnnoItem = 0
        totalAnnoItems = 0
        annotationItems.removeAll(keepingCapacity: true)
        await getMapPoints()
        // move map back to current spot
        cameraPosition = currentCameraPosition!
    }
    
    private func refreshMap() async {
//        let tempCurrentAnnoItem = currentAnnoItem
        // remember current map camera position
        currentCameraPosition = cameraPosition
        annotationItems.removeAll(keepingCapacity: true)  // or false?
        await getMapPoints()
        // move map back to current spot
        cameraPosition = currentCameraPosition!
//        currentAnnoItem = tempCurrentAnnoItem
    }
    
    // If stream is off, display alert. GPS coords are set to 0 in NMEADataClass. (Camera pop up now has the NMEA stream)
//    private func checkActiveNMEAStream() {
//        if nmea.hasNMEAStreamStopped ||
//             ((nmea.accuracy ?? "0.00") == "0.00" || (nmea.longitude ?? "0.0000") == "0.0000" ||
//              (nmea.latitude ?? "0.0000") == "0.0000" || (nmea.altitude ?? "0.00") == "0.00")
//        {
//            showAlert = true
//        }
//    }
    
    // Make sure forward and backward cycling will stay within the annotation's item count.
    private func cycleAnnotations (forward: Bool, _ offset: Int ){
        
        var offsetColor: Color
        
        // Get current annotation's color
        offsetColor = annotationItems[currentAnnoItem].highlightColor
        
        if forward { 
            // offset should be -1
            if currentAnnoItem < totalAnnoItems{
                currentAnnoItem += 1
                highlightAnnotation(offset, offsetColor)
            }
        }
        else {
            // offset should be 1
            if currentAnnoItem > 0 {
                currentAnnoItem -= 1
                highlightAnnotation(offset, offsetColor)
            }
        }
    }
    
    // Draw attention to selected point. Put previous or next point back to its original state
    private func highlightAnnotation (_ offset: Int, _ currentColor: Color){
        annotationItems[currentAnnoItem].size = 20
        // If currentAnnoItem is blue, make it light blue. Else make it red
        if annotationItems[currentAnnoItem].highlightColor == Color(red: 0, green: 0, blue: 1) {
            annotationItems[currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
        } else {
            annotationItems[currentAnnoItem].highlightColor = Color(red: 1, green: 0, blue: 0)
        }
        
        annotationItems[currentAnnoItem + offset].size = MapPointSize().size
        // If offsetColor is red, make it grey. Else make it blue
        if annotationItems[currentAnnoItem + offset].highlightColor == Color(red: 1, green: 0, blue: 0) {
            annotationItems[currentAnnoItem + offset].highlightColor = Color(red: 0.5, green: 0.5, blue: 0.5)
        } else {
            annotationItems[currentAnnoItem + offset].highlightColor = Color(red: 0, green: 0, blue: 1)
        }
    }
    
    // Get points from database
    private func getMapPoints () async {

        guard let url: URL = URL(string: settings[0].databaseURL + "/php/getMapItemsForApp.php") else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "_column_name=\(columnName)&_column_value=\(tripName)&_org_name=\(organismName)&_query_name=\(queryName)"
        
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
                            routeID: result.routeID,
                            pointOrder: result.pointOrder,
                            organismName: result.organismName,
                            systemName: "xmark.diamond.fill",
                            highlightColor: Color (
                                red: Double(result.r) ?? 0,
                                green: Double(result.g) ?? 0,
                                blue: Double(result.b) ?? 0
                            )
                        ))
                    }
                    
                    // Set staring regoin to the first point in the list
                    // For 17.0's new MapKit SDK:
                    self.cameraPosition = MapCameraPosition.region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: Double(mapResults[0].lat) ?? 0, longitude: Double(mapResults[0].long) ?? 0),
                            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                    ))
                    
                    // Toggle next and previous arrows(???)
                    if hasMapPointsResults == false {
                        hasMapPointsResults.toggle()
                    }                         
                    
                    // Release memory?
                    self.mapResults = [TempMapPointModel]()
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
    
    private func updatePointColor(routeID: String, pointOrder: String) async {
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/updateRoutePointColor.php") else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "_route_id=\(routeID)&_point_order=\(pointOrder)"
        
        let postData = postString.data(using: .utf8)
        
        // Insert pic and geo data into trip table. Use max ID of the same trip name
        do {
            
            let (_, _) = try await URLSession.shared.upload(for: request as URLRequest, from: postData!, delegate: nil)
            
            // Mark currently seleted point as "done"
            annotationItems[currentAnnoItem].highlightColor = Color(red: 0.5, green: 0.5, blue: 1)
            
        } catch let error as NSError {
            NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
        }
        
    }
    
    // get distance and bearing to the next selected map point
//    private func getDistanceAndBearing () async {
//
//        guard let url: URL = URL(string: settings[0].databaseURL + "/php/getDistanceAndBearing.php") else {
//            Swift.print("invalid URL")
//            return
//        }
//        
//        var request: URLRequest = URLRequest(url: url)
//        request.httpMethod = "POST"
//        
//        let postString = "_start_long=\(startLong)&_start_lat=\(startLat)&_end_long=\(annotationItems[currentAnnoItem].longitude)&_end_lat=\(annotationItems[currentAnnoItem].latitude)"
//        
//        let postData = postString.data(using: .utf8)
//        
//            do {
//                let (data, _) = try await URLSession.shared.upload(for: request, from: postData!, delegate: nil)
//                
//                let decoder = JSONDecoder()
//                decoder.keyDecodingStrategy = .useDefaultKeys
//                decoder.dataDecodingStrategy = .deferredToData
//                decoder.dateDecodingStrategy = .deferredToDate
//                
//                // Get result
//                self.distanceAndBearingResult = try decoder.decode([TempDistanceAndBearingModel].self, from: data)
//                
//                // dont update vars if result is empty
//                if !distanceAndBearingResult.isEmpty {
//                    
//                    // Put results in an vars
//                    for result in distanceAndBearingResult {
//                        distance.self = result.distance
//                        bearing.self = result.bearing
//                    }
//                    
//                    // Don't show items if no data
//                    if hasDistanceAndBearingResult == false {
//                        hasDistanceAndBearingResult.toggle()
//                    }
//                }
//                
//            // Debug catching from https://www.hackingwithswift.com/forums/swiftui/decoding-json-data/3024
//            } catch DecodingError.keyNotFound(let key, let context) {
//                Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
//            } catch DecodingError.valueNotFound(let type, let context) {
//                Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
//            } catch DecodingError.typeMismatch(let type, let context) {
//                Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
//            } catch DecodingError.dataCorrupted(let context) {
//                Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
//            } catch let error as NSError {
//                NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
//            } catch {
//                distanceAndBearingResult = distanceAndBearingResult
//            }
//    }//end get distance and bearing

    private func checkUserData() -> Bool {
        var isValid = false
        
        numofmatches = 0
        
        // Remove special characters from user data
        let pattern = "[^A-Za-z0-9,.:;\\s_\\-]+"
        textNotes = textNotes.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        
//        // remove any text past the final ;
//        pattern = "[A-Za-z0-9\\s]*$"
//        textNotes = textNotes.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        
        // Count # of proper syntax matches
        let range = NSRange(location: 0, length: textNotes.utf16.count)
        let regex = try! NSRegularExpression(pattern: "[\\s\\d\\w,._\\-]+\\s*:\\s*[\\s\\d\\w,._\\-]+\\s*;\\s*")
        numofmatches = regex.numberOfMatches(in: textNotes, range: range)
        
        // Are both ; : more than 0? Are ; : counts equal? Is : equal to match count? Or is the field blank?
        let colonCount = textNotes.filter({ $0 == ":"}).count
        let semicolonCount = textNotes.filter({ $0 == ";"}).count
        
        if (
            (
                (colonCount > 0 && semicolonCount > 0)
                && colonCount == semicolonCount
                && colonCount == numofmatches
                && textNotes.count > 0
                && numofmatches > 0
            ) || textNotes.count == 0
        ) {
            isValid = true
        }
        
        return isValid
    }
    
    private func cancelPic(){
        isImageSelected = false
        isShowCamera = true
        textNotes = ""
    }
    
    private func showCompleteAlertToggle(){
        showingCompleteAlert.toggle()
    }
    
//    private func invalidSyntax(_ object: String){
//        article.title = "Invalid Syntax"
//        article.description = "The syntax \(object) is invalid!"
//    }
    
    private func clearCustomData(){
        textNotes = ""
    }
    
}// end MapView view

