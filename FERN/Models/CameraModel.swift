//
//  CameraModel.swift
//  FERN
//
//  Created by Hopp, Dan on 6/18/24.
//
//  Uses UIImage and saves to a custom folder

import SwiftUI

class CameraController: UIViewController {
    
    @Published var showPicButton = false
    @State private var isShowCamera = false
    @ObservedObject var recognizedContent = RecognizedContent()  // Should be in a class? It's own MVC?
    @State private var isRecognizing = false
    @State private var isImageSelected = false
    @State private var image = UIImage()
    @State private var showingStoppedNMEAAlert = false
    @State private var showingInvalidSyntaxAlert = false
    @State private var showingHDOPOverLimit = false
    @State private var textNotes = ""
    @State private var scrubbedNotes = ""
    @State private var numofmatches = 0
    @State private var showingCompleteAlert = false
    
    
    // Sounds
    let audio = playSound()
    
    // The BridgingCoordinator received from the SwiftUI View
    var cameraControllerBridgingCoordinator: CameraBridgingCoordinator!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set self to the BridgingCoordinator
        cameraControllerBridgingCoordinator.cameraController = self
    }
    
    func createTxtFileForTheDay(tripName: String) {
        do{
            // create new txt file for the day for GPS data.
            _ = try FieldWorkGPSFile.log(tripName: tripName, uuid: "", gps: "", hdop: "", longitude: "", latitude: "", altitude: "", scannedText: "", notes: "")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func processImage(useBluetooth: Bool, hasBTStreamStopped: Bool, hdopThreshold: Double, imgFile: UIImage, tripOrRouteName: String, uuid: String, gpsUsed: String, hdop: String = "0.00", longitude: String = "0.00000000", latitude: String = "0.00000000", altitude: String = "0.00", scannedText: String, notes: String) {  // RETURN BOOL
        
        var savePic = false
        
        if useBluetooth {
            // Alert user if feed has stopped or values are zero
            if hasBTStreamStopped || (hdop == "0.00" || longitude == "0.00000000" || latitude == "0.00000000" || altitude == "0.00")
            {
                audio.playError()
                isImageSelected = false
                showingStoppedNMEAAlert = true
            } else {
                savePic = true
            }
        } else {
            savePic = true
        }
        if savePic {
            savePicIfUnderThreshold(hdopThreshold: hdopThreshold, imgFile: imgFile, tripOrRouteName: tripOrRouteName, uuid: uuid, gpsUsed: gpsUsed, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude, scannedText: scannedText, notes: notes)
        }
    }
    
    func savePicIfUnderThreshold(hdopThreshold: Double, imgFile: UIImage, tripOrRouteName: String, uuid: String, gpsUsed: String, hdop: String, longitude: String, latitude: String, altitude: String, scannedText: String, notes: String) {
        // HDOP within the threshold?
        if Double(hdop) ?? 99.0 <= hdopThreshold {
            // Pass Bluetooth GPS data
            savePicToFolder(imgFile: image, tripOrRouteName: tripOrRouteName, uuid: uuid, gpsUsed: gpsUsed,
                            hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude,
                            scannedText: scannedText, notes: textNotes)
            
            setVarsAndViewAfterSuccessfulSave()
            
        } else {
            audio.playError()
            // Display hdop over threshold message
            showingHDOPOverLimit = true
        }
    }
    
    func savePicToFolder(imgFile: UIImage, tripOrRouteName: String, uuid: String, gpsUsed: String,
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
    
    func setVarsAndViewAfterSuccessfulSave() {
        isImageSelected = false
        isShowCamera = true
        showingInvalidSyntaxAlert = false
        showingHDOPOverLimit = false
        
        // pop view back down
        showPopover = false
    }
    
    func checkUserData() -> Bool {   // MOVE TO MAP MVC (MOVED)
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
    
    func cancelPic() {
        isImageSelected = false
        isShowCamera = true
        textNotes = ""
    }
    
    func showCompleteAlertToggle() {
        showingCompleteAlert.toggle()
    }
    
    func clearCustomData() {
        textNotes = ""
    }
    
}
