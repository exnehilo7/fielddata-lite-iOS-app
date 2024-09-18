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
    var openedFromMapView: Bool = false
    
    // Swift Data
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    @Query var sdTrips: [SDTrip]
    
    // View toggles
    @State private var isShowCamera = false
    @State private var showingStoppedNMEAAlert = false
    @State private var showingInvalidSyntaxAlert = false
    @State private var showingHDOPOverLimit = false
    @State private var showingCompleteAlert = false
    
    // Text scanning
    @State private var recognizedContent = RecognizedContent()
    @State private var isRecognizing = false
    
    // Image
    @State private var image = UIImage()

    
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

    
    //MARK: Views and Functions
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
            Label("Standard GPS",  systemImage: "location.fill").underline().foregroundColor(.blue)
            Text("Latitude: ") + Text("\(clLat)")
            Text("Longitude: ") + Text("\(clLong)")
            Text("Altitude (m): ") + Text("\(clAltitude)")
            Text("Horizontal Accuracy (m): ") + Text("\(clHorzAccuracy)").foregroundColor(getColor(text: clHorzAccuracy))
            Text("Vertical Accuracy (m): ") + Text("\(clVertAccuracy)")
        }.font(.system(size: 15))
            .padding()
    }
    //------------------------------------------------------------------
    
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
    
    // HDOP Over Threshold Alert
    var hdopOverLimitView: some View {
        VStack {
            Spacer()
            Text("HDOP Over Limit").bold().foregroundStyle(.red)
            Text("The horizontal position accuracy was over the limit of \(settings[0].hdopThreshold)!")
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
                Image(systemName: "photo")
                    .font(.system(size: 20))
                
                Text("Save Image")
                    .font(.headline)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(20)
            .padding(.horizontal)
        })
    }
    
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
                imageSuccessful = camera.processImage(useBluetooth: settings[0].useBluetoothDevice, hasBTStreamStopped: gps.nmea?.hasNMEAStreamStopped ?? false, hdopThreshold: settings[0].hdopThreshold, imgFile: image, tripOrRouteName: tripOrRouteName, uuid: upperUUID, gpsUsed: "ArrowGold", hdop: gps.nmea?.accuracy ?? "0.00", longitude: gps.nmea?.longitude ?? "0.00000000", latitude: gps.nmea?.latitude ?? "0.00000000", altitude: gps.nmea?.altitude ?? "0.00", scannedText: textInPic, notes: result.textNotes)
                long = gps.nmea?.longitude ?? "0.00000000"
                lat = gps.nmea?.latitude ?? "0.00000000"
                organismName = textInPic
                
            } else {
                imageSuccessful = camera.processImage(useBluetooth: settings[0].useBluetoothDevice, hasBTStreamStopped: true, hdopThreshold: settings[0].hdopThreshold, imgFile: image, tripOrRouteName: tripOrRouteName, uuid: upperUUID, gpsUsed: "iOS", hdop: clHorzAccuracy, longitude: clLong, latitude: clLat, altitude: clAltitude, scannedText: textInPic, notes: result.textNotes)
                
                long = clLong
                lat = clLat
                organismName = textInPic
            }
            
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
            
        } else {
            audio.playError()
            camera.showingInvalidSyntaxAlert = true
        }
    }
    
    // Show camera button
    var showCameraButton: some View {
        Button {
            camera.isShowCamera = true
            camera.showingStoppedNMEAAlert = false
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
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 20))
                
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
            .padding(.horizontal)
        })
    }
    
    // Fields for user to add custom metadata.
    var customData: some View {
        VStack {
            HStack {
                Text("Notes:")
                TextField("",
                          text: self.$camera.textNotes,
                          prompt: Text("branch count: 42; status: alive;").foregroundColor(.green.opacity(0.5))
                ).textFieldStyle(.roundedBorder).autocapitalization(.none).foregroundColor(.yellow)
            }
        }
    }
    
    // Swipe down chevron
    var swipeDownChevron: some View {
        Image(systemName: "chevron.compact.down").bold(false).foregroundColor(.white).font(.system(size:32))
    }
    
    //MARK: Main View
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
            if camera.showingStoppedNMEAAlert {
                stoppedNMEA
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
            
            if camera.isImageSelected {
                customData
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
            if !camera.isShowCamera {
                if settings[0].useBluetoothDevice {
                    arrowGpsData
                }
                else {
                    coreLocationGpsData
                }
            }
            
            // Display recognized text
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
            
            if camera.isImageSelected {
                HStack{
                    cancelPicButton
                }
            }
            
            HStack {
                
                // Show the image save button if ImagePicker struct has an image.
                if camera.isImageSelected {
                    HStack {
                        scanForTextButton
                    }
                    Spacer()
                    HStack {
                        savePicButton
                    }
                }
            }
        }.onAppear(perform: {
            // Create Text File for the Day
            camera.createImageTxtFileForTheDay(tripOrRouteName: tripOrRouteName)
        })
        .sheet(isPresented:
                $camera.isShowCamera) {
            // Show the GPS data at all times on the bottom half of the screen
            ZStack {
                Color.black.ignoresSafeArea(.all)
                VStack {
                    ImagePicker(sourceType: .camera, selectedImage: $camera.image, imageIsSelected: $camera.isImageSelected)
                    // GPS data on sheet
                    if settings[0].useBluetoothDevice {
                        arrowGpsData
                    }
                    else {
                        coreLocationGpsData
                    }
                }
            }
        }.animation(.easeInOut, value: true)
            .preferredColorScheme(.dark)
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
}
