//
//  CameraImageView.swift
//  FERN
//
//  Created by Hopp, Dan on 11/17/23. This is to look and function like CameraView, except use a folder-saveable .jpeg Image instead of iOS' restrictive Photo resource.
//
//[Camera] Attempted to change to mode Portrait with an unsupported device (BackWideDual). Auto device for both positions unsupported, returning Auto device for same position anyway (BackAuto).
//[Snapshotting] Snapshotting a view (0x107008200, UIKeyboardImpl) that is not in a visible window requires afterScreenUpdates:YES.

import SwiftUI
//import Foundation

struct CameraImageView: View {
    
    // TEMP VAR TILL CAMERA IS REPLACED WITH IMAGE
    @StateObject var model = CameraService()
    
    // MARK: Vars
    // From calling view
    var tripName: String
    
    @State private var image = UIImage()
    @State private var isShowCamera = false
    @State private var isImageSelected = false
    
    // Alerts
    @State private var showAlert = false
    @State private var article = Article(title: "Device Feed Error", description: "Photo was not saved. Check the Bluetooth or satellite connection. If both are OK, try killing and restarting the app.")
    
    // Select GPS and display toggles
    @State var gpsModeIsSelected = false
    @State var showArrowGold = false
    
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
        }.font(.system(size: 18)).foregroundColor(.white)
    }
    
    // iOS Core Location
    var coreLocationGpsData: some View {
        VStack {
            
            Label("Standard GPS (May need time to start feed)",  systemImage: "location.fill").underline()
            Text("Latitude: ") + Text("\(clLat)")
            Text("Longitude: ") + Text("\(clLong)")
            Text("Altitude (m): ") + Text("\(clAltitude)")
            Text("Horizontal Accuracy (m): ") + Text("\(clHorzAccuracy)")
            Text("Vertical Accuracy (m): ") + Text("\(clVertAccuracy)")
        }.font(.system(size: 15)).foregroundColor(.white)
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
            if showArrowGold {
                // Alert user if feed has stopped or values are zero
                if nmea.hasNMEAStreamStopped ||
                    ((nmea.accuracy ?? "0.00") == "0.00" || (nmea.longitude ?? "0.0000") == "0.0000" ||
                     (nmea.latitude ?? "0.0000") == "0.0000" || (nmea.altitude ?? "0.00") == "0.00")
                {
                    showAlert = true
                    isShowCamera = false
                } else {
                    // Pass Arrow GPS data
                    savePicToFolder(imgFile: image, tripName: tripName, uuid: upperUUID, gps: "ArrowGold", hdop: nmea.accuracy ?? "0.00", longitude: nmea.longitude ?? "0.0000", latitude: nmea.latitude ?? "0.0000", altitude: nmea.altitude ?? "0.00")
                    isImageSelected = false
                    isShowCamera = true
                }
            } else {
                // Pass default GPS data
                savePicToFolder(imgFile: image, tripName: tripName, uuid: upperUUID, gps: "iOS", hdop: clHorzAccuracy, longitude: clLong, latitude: clLat, altitude: clAltitude)
                isImageSelected = false
                isShowCamera = true
            }
            
            // Clear displayed image (if previous image feedback is needed, borrow capturedPhotoThumbnail from CameraView? 
            self.image = UIImage()

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
        }).alert(article.title, isPresented: $showAlert, presenting: article) {article in Button("OK"){showAlert = false; isImageSelected = false
}} message: {article in Text(article.description)}
    }
    
    // Show the camera button (for if the user cancels a photo
    var showCameraButton: some View {
        Button {
            isShowCamera = true
        } label: {
            Label("Show Camera", systemImage: "camera").foregroundColor(.white)
        }.buttonStyle(.borderedProminent).tint(.blue)
    }
    
    // Test fields for user to add custom metadata. Will need to create @State private var's
//    var userData: some View {
//        VStack {
//            HStack {
//                Text("Photo Group: ").foregroundColor(.white)
//                TextField("", text: $textPhotoGroup
//                ).textFieldStyle(.roundedBorder)
//            }
//            HStack {
//                Text("Organism Name: ").foregroundColor(.white)
//                TextField("", text: $textOrganismName
//                ).textFieldStyle(.roundedBorder)
//            }
//            HStack {
//                Text("Genotype: ").foregroundColor(.white)
//                TextField("", text: $textGenotype
//                ).textFieldStyle(.roundedBorder)
//            }
//            HStack {
//                Text("Notes: ").foregroundColor(.white)
//                TextField("", text: $textNotes
//                ).textFieldStyle(.roundedBorder)
//            }
//        }
//    }
    
    // MARK: Functions
    private func createTxtFileForTheDay() {
        do{
            // create new txt file for the day for GPS data.
            _ = try FieldWorkGPSFile.log(tripName: tripName, uuid: "", gps: "", hdop: "", longitude: "", latitude: "", altitude: "")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func savePicToFolder(imgFile: UIImage, tripName: String, uuid: String, gps: String, hdop: String, longitude: String, latitude: String, altitude: String) {
        do{
            // Save image to Trip's folder
            try _ = FieldWorkImageFile.saveToFolder(imgFile: imgFile, tripName: tripName, uuid: uuid, gps: gps, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude)
        } catch {
            print(error.localizedDescription)
        }
        
        // Write the pic's info to a .txt file
        do {
            // .txt file header order is uuid, gps, hdop, longitude, latitude, altitude.
            try _ = FieldWorkGPSFile.log(tripName: tripName, uuid: uuid, gps: gps, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            print(error.localizedDescription)
        }
    }
    
    // MARK: Body
    var body: some View {
        VStack {
            // Show the pic to be saved
            Image(uiImage: self.image)
            .resizable()
            .scaledToFit()
                
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
                if !isShowCamera{
                    if showArrowGold {
                        arrowGpsData
                    }
                    else {
                        coreLocationGpsData
                    }
                }
                
                Spacer()
                
                HStack {
                    
                    Spacer()
                    // Show the image save button if ImagePicker struct has an image.
                    if isImageSelected {
                        savePicButton
                    }
                    
                    Spacer()
                    
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
        }.animation(.easeInOut, value: true) // END VStack
    } // END BODY
    
} // END STRUCT

//#Preview {
//    CameraImageView()
//}
