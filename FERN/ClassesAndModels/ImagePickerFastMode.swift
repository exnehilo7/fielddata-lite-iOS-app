//
//  ImagePickerFastMode.swift
//  FERN
//
//  Created by Hopp, Dan on 5/30/24.
//

import Foundation
import SwiftUI
import UIKit

struct ImagePickerFastMode: UIViewControllerRepresentable {
 
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @Binding var selectedImage: UIImage
    @Environment(\.presentationMode) private var presentationMode
    
    // Vars to function with TripModeFastCameraView
//    @State var tripName: String
//    @State var nmea:NMEA
//    @State var clLat:String
//    @State var clLong:String
//    @State var clHorzAccuracy:String
//    @State var clVertAccuracy:String
//    @State var clAltitude:String
//    @Binding var gpsModeIsSelected: Bool
//    @Binding var showArrowGold: Bool
//    @Binding var isShowCamera: Bool
    @Binding var isImageSelected : Bool
//    @Binding var showAlert : Bool
//    var article = Article(title: "", description: "")
    
//    
//    var savePicButton: some View {
//        Button(action: {
//            if let image = UIImagePickerController.InfoKey.originalImage {
//                selectedImage = image
//            }
//        }, label: {
//            HStack {
//                Image(systemName: "photo")
//                    .font(.system(size: 20))//.foregroundColor(.green)
//                
//                Text("Save Image")
//                    .font(.headline)
//            }
//            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
//            .background(Color.orange)
//            .foregroundColor(.white)
//            .cornerRadius(20)
//            .padding(.horizontal)
//        })
//    }
    
 
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePickerFastMode>) -> UIImagePickerController {
 
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        imagePicker.showsCameraControls = false
//        imageIsSelected = false

        return imagePicker
    }
    
 
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePickerFastMode>) {
 
    }
    
    func makeCoordinator() -> Coordinator {
          Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
     
        var parent: ImagePickerFastMode
     
        init(_ parent: ImagePickerFastMode) {
            self.parent = parent
        }
     
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
     
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
                
//                let fileNameUUID = UUID().uuidString
//                let upperUUID = fileNameUUID.uppercased()
//                if parent.showArrowGold {
//                        // Alert user if feed has stopped or values are zero
//                    if parent.nmea.hasNMEAStreamStopped ||
//                        ((parent.nmea.accuracy ?? "0.00") == "0.00" || (parent.nmea.longitude ?? "0.00000000") == "0.00000000" ||
//                         (parent.nmea.latitude ?? "0.00") == "0.00000000" || (parent.nmea.altitude ?? "0.00") == "0.00")
//                        {
//                            // GPS coords are set to 0 in NMEADataClass
//                        parent.article.title = "Device Feed Error"
//                        parent.article.description = "Photo was not saved. Check the Bluetooth or satellite connection. If both are OK, try killing and restarting the app."
//                        parent.showAlert = true
//                        parent.isImageSelected = false
//    //                        showingStoppedNMEAAlert = true
//                        } else {
//                            // Pass Arrow GPS data
//                            ImagePickerFastMode.savePicToFolderFastMode(imgFile: image, tripName: parent.tripName, uuid: upperUUID, gps: "ArrowGold", hdop: parent.nmea.accuracy ?? "0.00", longitude: parent.nmea.longitude ?? "0.0000",
//                                latitude: parent.nmea.latitude ?? "0.0000", altitude: parent.nmea.altitude ?? "0.00", scannedText: "", notes: "")
//                            parent.isImageSelected = true
//                            parent.isShowCamera = true
//                        }
//                    } else {
//                        // Pass default GPS data
//                        ImagePickerFastMode.savePicToFolderFastMode(imgFile: image, tripName: parent.tripName, uuid: upperUUID, gps: "iOS",
//                                                                    hdop: parent.clHorzAccuracy, longitude: parent.clLong, latitude: parent.clLat, altitude: parent.clAltitude,
//                                        scannedText: "", notes: "")
//                        parent.isImageSelected = true
//                        parent.isShowCamera = true
//                    }
//                image = UIImage()
            }
//            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
//    // Code to save pic and its data
//    static func savePicToFolderFastMode(imgFile: UIImage, tripName: String, uuid: String, gps: String,
//                                 hdop: String, longitude: String, latitude: String, altitude: String,
//                                 scannedText: String, notes: String) {
//        
//        let audio = playSound()
//        
//        do {
//            // Save image to Trip's folder
//            try _ = FieldWorkImageFile.saveToFolder(imgFile: imgFile, tripName: tripName, uuid: uuid, gps: gps, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude)
//        } catch {
//            print(error.localizedDescription)
//            audio.playError()
//        }
//        
//        // Write the pic's info to a .txt file
//        do {
//            // .txt file header order is uuid, gps, hdop, longitude, latitude, altitude.
//            try _ = FieldWorkGPSFile.log(tripName: tripName, uuid: uuid, gps: gps, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude, scannedText: scannedText, notes: notes)
//            // Play a success noise
//            audio.playSuccess()
//        } catch {
//            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
//            print(error.localizedDescription)
//            audio.playError()
//        }
//    }
    
}
