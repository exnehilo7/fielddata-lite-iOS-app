//
//  CameraImageView.swift
//  FERN
//
//  Created by Hopp, Dan on 11/17/23. This is to look and function like CameraView, except use a folder-saveable .jpeg Image instead of iOS' restrictive Photo resource.
//

import SwiftUI
import Foundation

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
    @State private var article = Article(title: "Device Feed Error", description: "No photo was taken. Check the Bluetooth or satellite connection. If both are OK, try killing and restarting the app.")
    
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
            Text("Altitude: ") + Text(nmea.altitude ?? "0.00")
            Text("Horizontal Accuracy: ") + Text(nmea.accuracy ?? "0.00")
            Text("GPS Used: ") + Text(nmea.gpsUsed ?? "No GPS")
        }.font(.system(size: 20)).foregroundColor(.white)
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
        }.font(.system(size: 20)).foregroundColor(.white)
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
    
    // Take a pic button
    var captureButton: some View {
        Button(action: {
            if isImageSelected {
                let fileNameUUID = UUID().uuidString
                let upperUUID = fileNameUUID.uppercased()
                if showArrowGold {
                    if nmea.hasNMEAStreamStopped ||
                        (model.hdop == "0.00" || model.longitude == "0.0000" ||
                         model.latitude == "0.0000" || model.altitude == "0.00")
                    {
                        showAlert = true
                    } else {
                        // Pass Arrow GPS data
                        savePicToFolder(imgFile: image, tripName: tripName, uuid: upperUUID, gps: "ArrowGold", hdop: nmea.accuracy ?? "0.00", longitude: nmea.longitude ?? "0.0000", latitude: nmea.latitude ?? "0.0000", altitude: nmea.altitude ?? "0.00")
                    }
                } else {
                    // Pass default GPS data
                    savePicToFolder(imgFile: image, tripName: tripName, uuid: upperUUID, gps: "iOS", hdop: clHorzAccuracy, longitude: clLong, latitude: clLat, altitude: clAltitude)
                }
                
                // Clear displayed image
                self.image = UIImage()
                
                isImageSelected = false
            }
            
//            // Pass trip name
//            model.tripName = tripName
//            if showArrowGold {
//                // Pass Arrow GPS data
//                model.gps = "ArrowGold"
//                model.hdop = nmea.accuracy ?? "0.00"
//                model.longitude = nmea.longitude ?? "0.0000"
//                model.latitude = nmea.latitude ?? "0.0000"
//                model.altitude = nmea.altitude ?? "0.00"
//                
//                // If there's no feed, don't capture the photo
//                if nmea.hasNMEAStreamStopped ||
//                    (model.hdop == "0.00" || model.longitude == "0.0000" ||
//                     model.latitude == "0.0000" || model.altitude == "0.00")
//                {
//                    model.photo = nil
//                    showAlert = true
//                } else {
////                    model.capturePhoto()
//                }
//            } else {
//                // Pass default GPS data
//                model.gps = "iOS"
//                model.hdop = clHorzAccuracy
//                model.longitude = clLong
//                model.latitude = clLat
//                model.altitude = clAltitude
////                model.capturePhoto()
//            }
        }, label: {
            Circle()
                .foregroundColor(.white)
                .frame(width: 80, height: 80, alignment: .center)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.8), lineWidth: 2)
                        .frame(width: 65, height: 65, alignment: .center)
                )
        }).alert(article.title, isPresented: $showAlert, presenting: article) {article in Button("OK"){showAlert = false}} message: {article in Text(article.description)}
    }
    
    // Thumbnal for photo taken feedback
    var capturedPhotoThumbnail: some View {
        Group {
            if image != nil {
                VStack {
                    // Original code had a thumbnail pop up
                    Image(uiImage: (image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .animation(.spring(), value: true)
                    //                // Try button popup
                    //                    .onAppear(perform: {isShowUploadButton = true})
                    Text("Pic taken!").foregroundColor(.white)
                }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 60, height: 60, alignment: .center)
                    .foregroundColor(.black)
            }
        }
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
            _ = try FieldWorkImageFile.saveToFolder(imgFile: imgFile, tripName: tripName, uuid: uuid, gps: gps, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude)
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
        GeometryReader { reader in
            ZStack {
                Color.black.ignoresSafeArea(.all)
                VStack { // Image V-stack
                    Text("Insert Image preview/iOS cam here.").foregroundStyle(.green)
                Image(uiImage: self.image)
                    .resizable()
                    .scaledToFit()
                    
                    if gpsModeIsSelected {
                        if showArrowGold {
                            arrowGpsData
                        }
                        else {
                            coreLocationGpsData
                        }
                        
                        Spacer()
                               
                        HStack {
                            capturedPhotoThumbnail

                            Spacer()
                            captureButton
                            Spacer()
                            
                        }
                    }
                    else {
                        selectGpsMode
                    }
                }.sheet(isPresented: $isShowCamera) { // Image V-stack
        ImagePicker(sourceType: .camera, selectedImage: self.$image, imageIsSelected: self.$isImageSelected) // Image V-stack
    }.animation(.easeInOut, value: true) // Image V-stack
            }
        }//.preferredColorScheme(.dark) // Make the status bar show on black background
    } // END BODY
    
} // END STRUCT

//#Preview {
//    CameraImageView()
//}
