//
//  UploadImageView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/23/23. Image picker help from https://www.appcoda.com/swiftui-camera-photo-library/
// Was used to try uploading an image to a server.

import SwiftUI
import UIKit

struct UploadImageView: View {
    
    // GPS
    @ObservedObject var nmea:NMEA = NMEA()
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
    
    // Select GPS and display toggles
    @State var gpsModeIsSelected = false
    @State var showArrowGold = false
    
    @State private var isShowCamera = false
//    @State private var isResponseReceived = false
    @State private var isShowUploadButton = false
    @State private var image = UIImage()
    
    @ObservedObject var uploadImage = UploadImage()
    let myPickerController = UIImagePickerController()
    
    var arrowGpsData: some View {
        VStack {
            // Arrow Gold
            Label("EOS Arrow Gold", systemImage: "antenna.radiowaves.left.and.right").underline()
//            Text("Protocol: ") + Text(nmea.protocolText as String)
            Text("Latitude: ") + Text(nmea.latitude ?? "0.0000")
            Text("Longitude: ") + Text(nmea.longitude ?? "0.0000")
            Text("Altitude (m): ") + Text(nmea.altitude ?? "0.00")
            Text("Horizontal Accuracy (m): ") + Text(nmea.accuracy ?? "0.00")
            Text("GPS Used: ") + Text(nmea.gpsUsed ?? "No GPS")
        }.font(.system(size: 20))
    }
    
    var coreLocationGpsData: some View {
        VStack {
            // Default Core Location
            Label("Standard GPS",  systemImage: "location.fill").underline()
            Text("Latitude: ") + Text("\(clLat)")
            Text("Longitude: ") + Text("\(clLong)")
            Text("Altitude (m): ") + Text("\(clAltitude)")
            Text("Horizontal Accuracy (m): ") + Text("\(clHorzAccuracy)")
            Text("Vertical Accuracy (m): ") + Text("\(clVertAccuracy)")
        }.font(.system(size: 20))
            .padding()
    }
    
    var selectGpsMode: some View {
        HStack {
            Button{
                gpsModeIsSelected = true
            } label: {
                Label("Use Standard GPS", systemImage: "location.fill")
            }.buttonStyle(.borderedProminent)
            Button{
                showArrowGold = true
                clLocationHelper.stopUpdatingDefaultCoreLocation() // basic core off
                nmea.viewDidLoad()
                gpsModeIsSelected = true
            } label: {
                Label("Use Arrow Gold Device", systemImage: "antenna.radiowaves.left.and.right")
            }.buttonStyle(.borderedProminent)
        }
    }
    
    // Get a message from Upload Image
    var responseMessage: some View {
        VStack {
            Text("PHP Response: \(uploadImage.responseString ?? "None")")
        }.font(.system(size: 20))
            .padding()
    }
    
    var body: some View {
        VStack {
         
            Image(uiImage: self.image)
                .resizable()
                .scaledToFit()
//                .frame(minWidth: 0, maxWidth: .infinity)  // Deprecated
//                .edgesIgnoringSafeArea(.all)              // Deprecated
 
            VStack {
                if gpsModeIsSelected {
                    if showArrowGold {
                        arrowGpsData
                    }
                    else {
                        coreLocationGpsData
                    }
                    
                    Spacer()
                    
                    responseMessage
                    
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            self.isShowCamera = true
                            uploadImage.setResponseMsgToBlank()
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                
                                Text("Photo")
                                    .font(.headline)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .padding(.horizontal)
                        }
                        if isShowUploadButton {
                            Button(action: {
                                
//                                var lat: String!
//                                var long: String!
//                                if showArrowGold {
//                                    lat = nmea.latitude ?? "0.0000"
//                                    long = nmea.longitude ?? "0.0000"
//                                }
//                                else {
//                                    lat = clLat
//                                    long = clLong
//                                }
                                
                                //                    uploadImage.myImageUploadRequestTEST()
//                                uploadImage.myImageUploadRequest(theImage: self.image, lat: lat, long: long)

                                // NEED TO TELL IF UPLOAD WAS SUCESSFUL OR NOT
                                // Present response to user
                                // isResponseReceived = uploadImage.isResponseReceived

                                // Clear displayed image
                                self.image = UIImage()
                                
                                // Hide upload button
                                isShowUploadButton = false
                            })
                            {
                                HStack {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 20))
                                    
                                    Text("Upload Image")
                                        .font(.headline)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                }
                else {
                    selectGpsMode
                }
            }.animation(.easeInOut, value: true)
            
            

        }.sheet(isPresented: $isShowCamera) {
            ImagePicker(sourceType: .camera, selectedImage: self.$image, imageIsSelected: self.$isShowUploadButton)
        }.animation(.easeInOut, value: true)
        
//        HStack {
//            Button("Select Photos") {
////                myPickerController.delegate = self
////                myPickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
////
////                self.presentViewController(myPickerController, animated: true, completion: nil)
//            }.buttonStyle(.borderedProminent)
//            Button("Upload Images") {
//                uploadImage.myImageUploadRequest()
//            }
//        }
    }
    
}

//struct UploadImageView_Previews: PreviewProvider {
//    static var previews: some View {
//        UploadImageView()
//    }
//}
