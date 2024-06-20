//
//  CameraImageView.swift
//  FERN
//
//  Created by Hopp, Dan on 11/17/23.
//
//  01-JUN-2024: Was replaced by TripModeThoroughCameraView and TripModeFastCameraView

import SwiftUI
import SwiftData

struct CameraImageView: View {
    
    // MARK: Vars
    // From calling view
    var mapViewIsActive: Bool
    var tripName: String
    
//    let reloadPointsOnMapWithNMEAView: () async -> ()
    
    // Image var and camera/image toggles
    @State private var image = UIImage()
    @State private var isShowCamera = false
    @State private var isImageSelected = false
    
    // Alerts
    @State private var showAlert = false
    @State private var article = Article(title: "", description: "")
    @State private var showingCompleteAlert = false
    @State private var showingStoppedNMEAAlert = false
    @State private var showingHDOPOverLimit = false
    
    // Select GPS and display toggles
//    @State var gpsModeIsSelected = false
//    @State var showArrowGold = false
    var showArrowGold:Bool
    var gpsModeIsSelected:Bool
    
    // Swift data
    @Environment(\.modelContext) var modelContext
    @Query var sdTrips: [SDTrip]
    @Query var settings: [Settings]
    
    // Text recognition
    @ObservedObject var recognizedContent = RecognizedContent()
    @State private var isRecognizing = false
//    @State var scannedText = ""
    
    // Custom Data
    @State private var textNotes = ""
    @State private var scrubbedNotes = ""
    @State private var numofmatches = 0
    
    // Audio
    let audio = playSound()
    
    // GPS -------------------------------------------------------------
    // Arrow Gold
//    @ObservedObject var nmea:NMEA = NMEA()
    var nmea: NMEA
    
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
            
            Label("EOS Arrow Gold", systemImage: "antenna.radiowaves.left.and.right").underline().foregroundColor(.yellow)
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
    
    // Select GPS mode
//    var selectGpsMode: some View {
//        HStack {
//            HStack{
//                Button{
//                    // (22-AUG-2023: Need to initiate the camera class(?) and CoreLocation on button press, not on view load?)
//                    gpsModeIsSelected = true
//                    createTxtFileForTheDay()
//                    UIApplication.shared.isIdleTimerDisabled = true
//                    isShowCamera = true
//                    // Clear scanned text
//                    recognizedContent.items[0].text = ""
//                } label: {
//                    Label("Use Standard GPS", systemImage: "location.fill")
//                }.buttonStyle(.borderedProminent)
//            }.padding(.leading, 20)
//            Spacer()
//            HStack{
//                Button{
//                    showArrowGold = true
//                    clLocationHelper.stopUpdatingDefaultCoreLocation() // basic core off
//                    nmea.viewDidLoad()
//                    gpsModeIsSelected = true
//                    createTxtFileForTheDay()
//                    // To prevent the device feed from being interruped, disable autosleep
//                    UIApplication.shared.isIdleTimerDisabled = true
//                    isShowCamera = true
//                    // Clear scanned text
//                    recognizedContent.items[0].text = ""
//                } label: {
//                    Label("Use Arrow Gold Device", systemImage: "antenna.radiowaves.left.and.right").foregroundColor(.black)
//                }.buttonStyle(.borderedProminent).tint(.yellow)
//            }.padding(.trailing, 20)
//        }
//    }
    
    // NMEA Alert
    var stoppedNMEA: some View {
        VStack {
            Spacer()
            Text("Device Feed Error").bold().foregroundStyle(.red)
            Text("Photo was not saved. Check the Bluetooth or satellite connection. If both are OK, try killing and restarting the app.")
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
            // if user data is all good, save pic
            if checkUserData() {
                
                processImage(upperUUID: upperUUID, textInPic: textInPic)
                
                // Clear displayed image (if previous image feedback is needed, borrow capturedPhotoThumbnail from CameraView?
                self.image = UIImage()
                // Clear scanned text
                recognizedContent.items[0].text = ""
                // Clear custom data
                clearCustomData()
            } else {invalidSyntax("for the Notes field"); showAlert = true} // end user notes check
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
//                                semaphore: DispatchSemaphore(value: 0)
                            )
//            scannedText = recognizedContent.items[0].text
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
    
    // MARK: Body
    var body: some View {
        
        VStack {
            // Don't show Mark Complete button if View was called from Map
            if !mapViewIsActive {
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
            }
            // No-NMEA alert
            if showingStoppedNMEAAlert {
                stoppedNMEA
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
//                // Don't show if an image is ready to save
//                if !isImageSelected {
//                    // Don't show if the camera is already showing
//                    if !isShowCamera {
//                        showCameraButton
//                    }
//                }
//            }
            
            // Show GPS feed if one was selected
//            if gpsModeIsSelected {
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
//                if recognizedContent.items[0].text != ""{
                    HStack {
                        Text("Scanned text: ")
                        TextPreviewView(scannedText: recognizedContent.items[0].text)
                        
                    }
//                TextField("", text: $scannedText)
//                        .font(.body)
//                        .padding()
//                }
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
//            }
//            else {
//                selectGpsMode
//            }
            
            // Don't show camera button if an image is ready to save or if the camera is already showing
            if !isImageSelected && !isShowCamera {
                showCameraButton
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
            .onAppear(perform: {
                if showArrowGold {
                    // basic core off. May need to better handle LocationHelper instantiation
                    clLocationHelper.stopUpdatingDefaultCoreLocation()
                }
                createTxtFileForTheDay()
                // To prevent the device feed from being interruped, disable autosleep
                UIApplication.shared.isIdleTimerDisabled = true
//                isShowCamera = true
                // Clear scanned text
                recognizedContent.items[0].text = ""
                // Show camera if View was first called from the Map View
                if mapViewIsActive {
                    isShowCamera = true
                }
            })// END VStack
    } // END BODY
    
    // MARK: Functions
    private func createTxtFileForTheDay() {
        do{
            // create new txt file for the day for GPS data.
            _ = try FieldWorkGPSFile.log(tripOrRouteName: tripName, uuid: "", gpsUsed: "", hdop: "", longitude: "", latitude: "", altitude: "", scannedText: "", notes: "")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    private func processImage(upperUUID: String, textInPic: String) {
        if showArrowGold {
            // Alert user if feed has stopped or values are zero
            if nmea.hasNMEAStreamStopped ||
                ((nmea.accuracy ?? "0.00") == "0.00" || (nmea.longitude ?? "0.00000000") == "0.00000000" ||
                 (nmea.latitude ?? "0.00") == "0.00000000" || (nmea.altitude ?? "0.00") == "0.00")
            {
                // GPS coords are set to 0 in NMEADataClass
                showingStoppedNMEAAlert = true
                isImageSelected = false
            } else {
                // HDOP within the threshold?
                if Double((nmea.accuracy ?? "0.00")) ?? 99.0 <= settings[0].hdopThreshold {
                    // Pass Arrow GPS data
                    savePicToFolder(imgFile: image, tripName: tripName, uuid: upperUUID, gps: "ArrowGold",
                                    hdop: nmea.accuracy ?? "0.00", longitude: nmea.longitude ?? "0.0000", latitude: nmea.latitude ?? "0.0000", altitude: nmea.altitude ?? "0.00",
                                    scannedText: textInPic, notes: textNotes)
                    setVarsAfterSuccessfulSave()
                } else {
                    audio.playError()
                    // Display hdop over threshold message
                    showingHDOPOverLimit = true
                }
            }
        } else {
            if Double((clHorzAccuracy)) ?? 99.0 <= settings[0].hdopThreshold {
                // Pass default GPS data
                savePicToFolder(imgFile: image, tripName: tripName, uuid: upperUUID, gps: "iOS",
                                hdop: clHorzAccuracy, longitude: clLong, latitude: clLat, altitude: clAltitude,
                                scannedText: textInPic, notes: textNotes)
                setVarsAfterSuccessfulSave()
            }  else {
                audio.playError()
                // Display hdop over threshold message
                showingHDOPOverLimit = true
            }
        }
    }
    
    private func setVarsAfterSuccessfulSave() {
        isImageSelected = false
        isShowCamera = true
        showingHDOPOverLimit = false
    }
    
    private func savePicToFolder(imgFile: UIImage, tripName: String, uuid: String, gps: String, 
                                 hdop: String, longitude: String, latitude: String, altitude: String,
                                 scannedText: String, notes: String) {
        
        do {
            // Save image to Trip's folder
            try _ = FieldWorkImageFile.saveToFolder(imgFile: imgFile, tripOrRouteName: tripName, uuid: uuid, gpsUsed: gps, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude)
        } catch {
            print(error.localizedDescription)
            audio.playError()
        }
        
        // Write the pic's info to a .txt file
        do {
            // .txt file header order is uuid, gps, hdop, longitude, latitude, altitude.
            try _ = FieldWorkGPSFile.log(tripOrRouteName: tripName, uuid: uuid, gpsUsed: gps, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude, scannedText: scannedText, notes: notes)
            // Play a success noise
            audio.playSuccess()
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            print(error.localizedDescription)
            audio.playError()
        }
    }
    
    private func insertPointIntoDatabase(tripName: String, uuid: String, gps: String,
                                       hdop: String, longitude: String, latitude: String, altitude: String,
                                       scannedText: String, notes: String) async {
        
//        let semaphore = DispatchSemaphore(value: 0)
        
        // Current datetime
        let formatterDateTime = DateFormatter()
        formatterDateTime.dateFormat = "yyyy-MM-dd HH:mm:ssx"
        let timestamp = formatterDateTime.string(from: Date())
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/insertSingleTrip.php") else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "_name=\(tripName)&_pic_uuid=\(uuid)&_gps=\(gps)&_hdop=\(hdop)&_long=\(longitude)&_lat=\(latitude)&_alt=\(altitude)&_scanned_text=\(scannedText)&_time=\(timestamp)&_notes=\(notes)"
        
        let postData = postString.data(using: .utf8)
        
        // Insert pic and geo data into trip table. Use max ID of the same trip name
        do {
            let (_, _) = try await URLSession.shared.upload(for: request as URLRequest, from: postData!, delegate: nil)
        } catch let error as NSError {
            NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
        }
        
    }

    private func checkUserData() -> Bool {
        var isValid = false
        
        // Remove special characters from user data
        let pattern = "[^A-Za-z0-9,.:;\\s]+"
        textNotes = textNotes.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        
//        // remove any text past the final ;
//        pattern = "[A-Za-z0-9\\s]*$"
//        textNotes = textNotes.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        
        // Count # of proper syntax matches
        let range = NSRange(location: 0, length: textNotes.utf16.count)
        let regex = try! NSRegularExpression(pattern: "[\\s\\d\\w,.]+\\s*:\\s*[\\s\\d\\w,.]+\\s*;\\s*")
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
    
    private func invalidSyntax(_ object: String){
        article.title = "Invalid Syntax"
        article.description = "The syntax \(object) is invalid!"
    }
    
    private func clearCustomData(){
        textNotes = ""
    }
    
} // END STRUCT

//#Preview {
//    CameraImageView()
//}
