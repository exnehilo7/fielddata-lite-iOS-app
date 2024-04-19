//
//  CameraImageView.swift
//  FERN
//
//  Created by Hopp, Dan on 11/17/23.
//

import SwiftUI
import SwiftData

struct CameraImageView: View {
    
    // MARK: Vars
    // From calling view
    var tripName: String
    
    // Image var and camera/image toggles
    @State private var image = UIImage()
    @State private var isShowCamera = false
    @State private var isImageSelected = false
    
    // Alerts
    @State private var showAlert = false
    @State private var article = Article(title: "", description: "")
    @State private var showingCompleteAlert = false
    
    // Select GPS and display toggles
    @State var gpsModeIsSelected = false
    @State var showArrowGold = false
    
    // Swift data
    @Environment(\.modelContext) var modelContext
    @Query var sdTrips: [SDTrip]
    
    // Text recognition
    @ObservedObject var recognizedContent = RecognizedContent()
    @State private var isRecognizing = false
    
    // Custom Data
    @State private var textNotes = ""
    
    // GPS -------------------------------------------------------------
    // Arrow Gold
    @ObservedObject var nmea:NMEA = NMEA()
    
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
    
    //MARK: View Sections
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
                    // (22-AUG-2023: Need to initiate the camera class(?) and CoreLocation on button press, not on view load?)
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
                    // To prevent the device feed from being interruped, disable autosleep
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
    
    // Save the pic button
    var savePicButton: some View {
        Button(action: {
            let fileNameUUID = UUID().uuidString
            let upperUUID = fileNameUUID.uppercased()
            let textInPic = recognizedContent.items[0].text
            // if ; count is not the same count as :, and matching count is not even, alert user "Invalid note pattern!" and clear text field.
            let colonCount = textNotes.filter({ $0 == ":"}).count
            let semicolonCount = textNotes.filter({ $0 == ";"}).count
            if colonCount == semicolonCount {
                if colonCount % 2 == 0 {
                    // if all is good, save pic
                    // Remove special characters from user data
                    let pattern = "[^A-Za-z0-9:;\\s]+"
                    textNotes = textNotes.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
                    if showArrowGold {
                        // Alert user if feed has stopped or values are zero
                        if nmea.hasNMEAStreamStopped ||
                            ((nmea.accuracy ?? "0.00") == "0.00" || (nmea.longitude ?? "0.0000") == "0.0000" ||
                             (nmea.latitude ?? "0.0000") == "0.0000" || (nmea.altitude ?? "0.00") == "0.00")
                        {
                            article.title = "Device Feed Error"
                            article.description = "Photo was not saved. Check the Bluetooth or satellite connection. If both are OK, try killing and restarting the app."
                            showAlert = true
                            isShowCamera = false
                            isImageSelected = false
                        } else {
                            // Pass Arrow GPS data
                            savePicToFolder(imgFile: image, tripName: tripName, uuid: upperUUID, gps: "ArrowGold",
                                            hdop: nmea.accuracy ?? "0.00", longitude: nmea.longitude ?? "0.0000", latitude: nmea.latitude ?? "0.0000", altitude: nmea.altitude ?? "0.00",
                                            scannedText: textInPic, notes: textNotes)
                            isImageSelected = false
                            isShowCamera = true
                        }
                    } else {
                        // Pass default GPS data
                        savePicToFolder(imgFile: image, tripName: tripName, uuid: upperUUID, gps: "iOS",
                                        hdop: clHorzAccuracy, longitude: clLong, latitude: clLat, altitude: clAltitude,
                                        scannedText: textInPic, notes: textNotes)
                        isImageSelected = false
                        isShowCamera = true
                    }
                    
                    // Clear displayed image (if previous image feedback is needed, borrow capturedPhotoThumbnail from CameraView?
                    self.image = UIImage()
                    // Clear scanned text
                    recognizedContent.items[0].text = ""
                    // Clear custom data
                    clearCustomData()
                } else {invalidSyntax("for the Notes field"); showAlert = true} // end is_even?
            } else {invalidSyntax("for the Notes field"); showAlert = true} // end count = count
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
        }).alert(article.title, isPresented: $showAlert, presenting: article) {article in Button("OK"){showAlert = false
        }} message: {article in Text(article.description)}
    }
    
    // Show the camera button (for if the user cancels a photo)
    var showCameraButton: some View {
        Button {
            isShowCamera = true
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
                            .recognizeText()
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
                TextField("branch count: 42; status: alive;", text: $textNotes
                ).textFieldStyle(.roundedBorder).autocapitalization(.none)
            }
        }
    }
    
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

    private func cancelPic(){
        isImageSelected = false
        isShowCamera = true
        textNotes = ""
    }
    
    private func showCompleteAlertToggle(){
        showingCompleteAlert.toggle()
    }
    
    private func invalidSyntax(_ object: String){
        article.title = "Invalid Syntax"
        article.description = "The syntax \(object) is invalid!"
    }
    
    private func clearCustomData(){
        textNotes = ""
    }
    
    // MARK: Body
    var body: some View {
        
        VStack {
            if !gpsModeIsSelected {
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
            }
            else {
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
            .preferredColorScheme(.dark)// END VStack
    } // END BODY
    
} // END STRUCT

//#Preview {
//    CameraImageView()
//}
