//
//  CameraClass.swift
//  FERN
//
//  Created by Hopp, Dan on 6/20/24.
//

import SwiftUI

@Observable class CameraClass {

    var isShowCamera = false
    var isImageSelected = false
    var image = UIImage()
    var showingStoppedNMEAAlert = false
    var showingInvalidSyntaxAlert = false
    var showingHDOPOverLimit = false
    var textNotes = ""
    private var numofmatches = 0
    var showingCompleteAlert = false
    var showHDOPSettingView = false
    
    
    // Sounds
    let audio = playSound()
    
    // create new txt file for the day for GPS data.
    func createImageTxtFileForTheDay(tripOrRouteName: String) {
        do {
            _ = try FieldWorkGPSFile.writePicDataToTxtFile(tripOrRouteName: tripOrRouteName, uuid: "", gpsUsed: "", hdop: "", longitude: "", latitude: "", altitude: "", scannedText: "", notes: "")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func processImage(useBluetooth: Bool, hasBTStreamStopped: Bool, hdopThreshold: Double, imgFile: UIImage, tripOrRouteName: String, uuid: String, gpsUsed: String, hdop: String = "0.00", longitude: String = "0.00000000", latitude: String = "0.00000000", altitude: String = "0.00", scannedText: String, notes: String) -> Bool {
        
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
            // Save pic to a folder and write metadata to a text file
            savePicIfUnderThreshold(hdopThreshold: hdopThreshold, imgFile: imgFile, tripOrRouteName: tripOrRouteName, uuid: uuid, gpsUsed: gpsUsed, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude, scannedText: scannedText, notes: notes)

            return true
        }
        
        return false
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
            try _ = FieldWorkImageFile.saveToFolder(imgFile: imgFile, tripOrRouteName: tripOrRouteName, uuid: uuid, gpsUsed: gpsUsed, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude)
        } catch {
            print(error.localizedDescription)
            audio.playError()
        }
        
        // Write the pic's info to a .txt file
        do {
            // .txt file header order is uuid, gps, hdop, longitude, latitude, altitude.
            try _ = FieldWorkGPSFile.writePicDataToTxtFile(tripOrRouteName: tripOrRouteName, uuid: uuid, gpsUsed: gpsUsed, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude, scannedText: scannedText, notes: notes)
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
    }
    
    func resetCamera() {
        image = UIImage()
        setVarsAndViewAfterSuccessfulSave()
    }
    
    func checkUserData(textNotes: String) -> (isValid: Bool, textNotes: String) {

        self.textNotes = textNotes
        var isValid = false
        
        numofmatches = 0
        
        // Remove special characters from user data
        let pattern = "[^A-Za-z0-9,.:;\\s_\\-]+"
        self.textNotes = textNotes.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        
        // Count # of proper syntax matches
        let range = NSRange(location: 0, length: self.textNotes.utf16.count)
        let regex = try! NSRegularExpression(pattern: "[\\s\\d\\w,._\\-]+\\s*:\\s*[\\s\\d\\w,._\\-]+\\s*;\\s*")
        numofmatches = regex.numberOfMatches(in: self.textNotes, range: range)
        
        // Are both ; : more than 0? Are ; : counts equal? Is : equal to match count? Or is the field blank?
        let colonCount = self.textNotes.filter({ $0 == ":"}).count
        let semicolonCount = self.textNotes.filter({ $0 == ";"}).count
        
        if (
            (
                (colonCount > 0 && semicolonCount > 0)
                && colonCount == semicolonCount
                && colonCount == numofmatches
                && self.textNotes.count > 0
                && numofmatches > 0
            ) || self.textNotes.count == 0
        ) {
            isValid = true
        }
        
        return (isValid: isValid, textNotes: self.textNotes)
    }
    
    func cancelPic() {
        isImageSelected = false
        isShowCamera = true
    }
    
    func showCompleteAlertToggle() {
        showingCompleteAlert.toggle()
    }
    
    func clearCustomData() {
        textNotes = ""
    }
    
}
