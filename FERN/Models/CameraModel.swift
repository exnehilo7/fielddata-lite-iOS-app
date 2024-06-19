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
    
    func createTxtFileForTheDay() {
        do{
            // create new txt file for the day for GPS data.
            _ = try FieldWorkGPSFile.log(tripName: tripName, uuid: "", gps: "", hdop: "", longitude: "", latitude: "", altitude: "", scannedText: "", notes: "")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func processImage(upperUUID: String, textInPic: String) {  // MOVE TO CAMERA MVC (moved to model)
        if showArrowGold {
            // Alert user if feed has stopped or values are zero
            if nmea.hasNMEAStreamStopped ||
                ((nmea.accuracy ?? "0.00") == "0.00" || (nmea.longitude ?? "0.00000000") == "0.00000000" ||
                 (nmea.latitude ?? "0.00") == "0.00000000" || (nmea.altitude ?? "0.00") == "0.00")
            {
                audio.playError()
                isImageSelected = false
                showingStoppedNMEAAlert = true
            } else {
                // HDOP within the threshold?
                if Double((nmea.accuracy ?? "0.00")) ?? 99.0 <= settings[0].hdopThreshold {
                    // Pass Arrow GPS data
                    savePicToFolder(imgFile: image, tripName: tripName, uuid: upperUUID, gps: "ArrowGold",
                                    hdop: nmea.accuracy ?? "0.00", longitude: nmea.longitude ?? "0.0000", latitude: nmea.latitude ?? "0.0000", altitude: nmea.altitude ?? "0.00",
                                    scannedText: textInPic, notes: textNotes)
                    
                    setVarsAndViewAfterSuccessfulSave()
                    
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
                setVarsAndViewAfterSuccessfulSave()
            } else {
                audio.playError()
                // Display hdop over threshold message
                showingHDOPOverLimit = true
            }
        }
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
