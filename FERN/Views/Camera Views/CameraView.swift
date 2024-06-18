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
    
    // Bridging coordinator
    @EnvironmentObject var G: GpsBridgingCoordinator
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    @Query var sdTrips: [SDTrip]
    
    @State private var showPicButton = false
    @State private var recognizedContent = RecognizedContent()  // Should be in a class? It's own MVC?
    @State private var isRecognizing = false
    @State private var textNotes = ""
    @State private var isShowCamera = false
    @State private var isImageSelected = false
    @State private var showingStoppedNMEAAlert = false
    @State private var showingInvalidSyntaxAlert = false
    @State private var showingHDOPOverLimit = false
    @State private var showingCompleteAlert = false
    
    
    // From calling view
    var tripOrRouteName: String
    
    // MOVE THESE TO A SOME VIEW DECLARATION CONTROLLED BY useBluetoothDevice?
    var clLat:String {
        return "\(G.gpsController.clLocationHelper?.lastLocation?.coordinate.latitude ?? 0.0000)"
    }
    var clLong:String {
        return "\(G.gpsController.clLocationHelper?.lastLocation?.coordinate.longitude ?? 0.0000)"
    }
    var clHorzAccuracy:String {
        return "\(G.gpsController.clLocationHelper?.lastLocation?.horizontalAccuracy ?? 0.00)"
    }
    var clVertAccuracy:String {
        return "\(G.gpsController.clLocationHelper?.lastLocation?.verticalAccuracy ?? 0.00)"
    }
    var clAltitude:String {
        return "\(G.gpsController.clLocationHelper?.lastLocation?.altitude ?? 0.0000)"
    }
    //------------------------------------------------------------------

    
    //MARK: Views
    // GPS Data Display ------------------------------------------------
    // Arrow Gold
    var arrowGpsData: some View {
        VStack {
            
            Label("EOS Arrow Gold", systemImage: "antenna.radiowaves.left.and.right").underline().foregroundColor(.yellow)
            //            Text("Protocol: ") + Text(G.gpsController.nmea?.protocolText as String)
            Text("Latitude: ") + Text(G.gpsController.nmea?.latitude ?? "0.0000")
            Text("Longitude: ") + Text(G.gpsController.nmea?.longitude ?? "0.0000")
            Text("Altitude (m): ") + Text(G.gpsController.nmea?.altitude ?? "0.00")
            Text("Horizontal Accuracy (m): ") + Text(G.gpsController.nmea?.accuracy ?? "0.00")
            Text("GPS Used: ") + Text(G.gpsController.nmea?.gpsUsed ?? "No GPS")
        }.font(.system(size: 18))//.foregroundColor(.white)
    }
    
    // iOS Core Location
    var coreLocationGpsData: some View {
        VStack {
            
            Label("Standard GPS",  systemImage: "location.fill").underline().foregroundColor(.blue)
            Text("Latitude: ") + Text("\(clLat)")
            Text("Longitude: ") + Text("\(clLong)")
            Text("Altitude (m): ") + Text("\(clAltitude)")
            Text("Horizontal Accuracy (m): ") + Text("\(clHorzAccuracy)")
            Text("Vertical Accuracy (m): ") + Text("\(clVertAccuracy)")
        }.font(.system(size: 15))//.foregroundColor(.white)
            .padding()
    }
    //------------------------------------------------------------------
    
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
            // WRAP IN FUNCTION AND PLACE CODE IN MODEL ----------------------------------------------------------------------
            // if user data is all good, save pic
            if checkUserData() {

                processImage(upperUUID: upperUUID, textInPic: textInPic)
                
                // Clear displayed image (if previous image feedback is needed, borrow capturedPhotoThumbnail from CameraView?
                self.image = UIImage()
                // Clear scanned text
                recognizedContent.items[0].text = ""
                // Clear custom data
                clearCustomData()
                
            } else {
                audio.playError()
                showingInvalidSyntaxAlert = true
            }// end user notes check
            // ----------------------------------------------------------------------------------------------------------------
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
    
    // Show the camera button (for if the user cancels a photo)
    var showCameraButton: some View {
        Button {
            // WRAP IN FUNCTION AND PLACE CODE IN MODEL ----------------------------------------------------------------------
            isShowCamera = true
            showingStoppedNMEAAlert = false
            // ----------------------------------------------------------------------------------------------------------------
        } label: {
            Label("Show Camera", systemImage: "camera").foregroundColor(.white)
        }.buttonStyle(.borderedProminent).tint(.blue)
    }
    
    // Scan for text button  // Have it in its own MVC to select possible matches from a list?
    var scanForTextButton: some View {
        Button(action: {
            // WRAP IN FUNCTION AND PLACE CODE IN MODEL ----------------------------------------------------------------------
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
            // ----------------------------------------------------------------------------------------------------------------
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
        Button(action: {
            // WRAP IN FUNCTION AND PLACE CODE IN MODEL -----------------------------------------------------------------------
            cancelPic()
            // ----------------------------------------------------------------------------------------------------------------
        },
        label: {HStack {
            Image(systemName: "arrow.triangle.2.circlepath.camera").font(.system(size: 15))
            Text("Redo").font(.system(size: 15))
        }
            .frame(minWidth: 0, maxWidth: 75, minHeight: 0, maxHeight: 30)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(20)
            .padding(.horizontal)
        })
    }
    
    // Fields for user to add custom metadata.
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
    
    // Need to call these somewhere: createTxtFileForTheDay()
    //MARK: Main View
    var body: some View {
        VStack {
            if !isImageSelected {
                // mark complete button
                ForEach(sdTrips) { item in
                    // Get the previous view's selected trip
                    if (item.name == tripOrRouteName){
                        Button {
                            // WRAP IN FUNCTION AND PLACE CODE IN MODEL --------------------------
                            showCompleteAlertToggle()
                            // -------------------------------------------------------------------
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
                                // WRAP IN FUNCTION AND PLACE CODE IN MODEL --------------------------------------------
                                item.isComplete = true
                                showCompleteAlertToggle()
                                // -------------------------------------------------------------------------------------
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
            
            if showingHDOPOverLimit {
                hdopOverLimitView
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
//            if gpsModeIsSelected {
                // Don't show if an image is ready to save
                if !isImageSelected {
                    // Don't show if the camera is already showing
                    if !isShowCamera {
                        showCameraButton
                    }
                }
//            }
            
            // Show GPS feed if one was selected
//            if gpsModeIsSelected {
                // Don't display GPS coords if sheet is displayed.
            if !isShowCamera {
                if settings[0].useBluetoothDevice {
                    arrowGpsData
                }
                else {
                    coreLocationGpsData
                }
            }
            
            // Display recognized text (remove list?)
            if isRecognizing {
                ProgressView() // Move to text scan MVC? Text scan class?
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
//            } else {
//                selectGpsMode
//            }
        }.sheet(isPresented: $isShowCamera) {
            // Try to show the GPS data at all times on the bottom half of the screen
            ZStack {
                Color.black.ignoresSafeArea(.all)
                VStack {
                    ImagePicker(sourceType: .camera, selectedImage: self.$image, imageIsSelected: self.$isImageSelected)//.presentationDetents([.fraction(0.6)])
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
}
