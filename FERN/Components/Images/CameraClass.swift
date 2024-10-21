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
    var showingNoStreamDataAlert = false
    var showingInvalidSyntaxAlert = false
    var showingHDOPOverLimit = false
    var textNotes = ""
    private var numofmatches = 0
    var showingCompleteAlert = false
    var showHDOPSettingView = false
    var snapshotLatitude = "0"
    var snapshotLongitude = "0"
    var snapshotAltitude = "0"
    var snapshotHorzAccuracy = "9999.99"
    
    
    // Sounds
    let audio = playSound()
    
    // create new txt file for the day for GPS data.
    func createImageCsvFileForTheDay(tripOrRouteName: String) async {
        do {
            _ = try FieldWorkGPSFile.writePicDataToCsvFile(tripOrRouteName: tripOrRouteName, fileNameUUID: "", gpsUsed: "", hdop: "", longitude: "", latitude: "", altitude: "", scannedText: "", notes: "")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // create Scoring File for the day
    func createScoringFileForTheDay(tripOrRouteName: String) async {
        do {
            _ = try FieldWorkScoringFile.writeScoreToCSVFile(tripOrRouteName: tripOrRouteName, fileNameUUID: "", fromView: "", longitude: "", latitude: "", organismName: "", score: "")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func saveScoreToTextFile(tripOrRouteName: String, fileNameUUID: String, longitude: String, latitude: String, organismName: String, score: String) async {
        
        await createScoringFileForTheDay(tripOrRouteName: tripOrRouteName)
        
//        let uuid = UUID().uuidString
            do {
                try _ = FieldWorkScoringFile.writeScoreToCSVFile(tripOrRouteName: tripOrRouteName, fileNameUUID: fileNameUUID, fromView: "Camera", longitude: longitude, latitude: latitude, organismName: organismName, score: score)
            } catch {
                print(error.localizedDescription)
            }
    }
    
//    func processImageOLD(useBluetooth: Bool, btStreamHasNoData: Bool, hdopThreshold: Double, imgFile: UIImage, tripOrRouteName: String, uuid: String, gpsUsed: String, hdop: String = "0.00", longitude: String = "0.00000000", latitude: String = "0.00000000", altitude: String = "0.00", scannedText: String, notes: String) -> Bool {
//
//        var savePic = false
//        
//        if useBluetooth {
//            // Alert user if feed has stopped or values are zero
//            if btStreamHasNoData || (hdop == "0.00" || longitude == "0.00000000" || latitude == "0.00000000" || altitude == "0.00")
//            {
//                audio.playError()
//                isImageSelected = false
//                showingNoStreamDataAlert = true
//                resetSnaphotCords()
//            } else {
//                savePic = true
//            }
//        } else {
//            savePic = true
//        }
//        if savePic {
//            // Save pic to a folder and write metadata to a text file
//            savePicIfUnderThreshold(hdopThreshold: hdopThreshold, imgFile: imgFile, tripOrRouteName: tripOrRouteName, uuid: uuid, gpsUsed: gpsUsed, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude, scannedText: scannedText, notes: notes)
//
//            return true
//        }
//        
//        return false
//    }
    
    func processImage(useBluetooth: Bool, btStreamHasNoData: Bool, btEndEventHasNoData: Bool, hdopThreshold: Double, imgFile: UIImage, tripOrRouteName: String, uuid: String, gpsUsed: String, scannedText: String, notes: String) async -> Bool {
        
        var savePic = false
        
        if useBluetooth {
            // Alert user if feed has stopped or values are zero
            if btStreamHasNoData || (snapshotHorzAccuracy == "0.00" || snapshotLongitude == "0.00000000" || snapshotLatitude == "0.00000000" || snapshotAltitude == "0.00")
            {
                audio.playError()
                isImageSelected = false
                showingNoStreamDataAlert = true
                resetSnaphotCords()
            } else {
                savePic = true
            }
        } else {
            savePic = true
        }
        if savePic {
            // Save pic to a folder and write metadata to a text file
            await savePicIfUnderThreshold(hdopThreshold: hdopThreshold, imgFile: imgFile, tripOrRouteName: tripOrRouteName, uuid: uuid, gpsUsed: gpsUsed, hdop: snapshotHorzAccuracy, longitude: snapshotLongitude, latitude: snapshotLatitude, altitude: snapshotAltitude, scannedText: scannedText, notes: notes)

            return true
        }
        
        return false
    }
    
    func savePicIfUnderThreshold(hdopThreshold: Double, imgFile: UIImage, tripOrRouteName: String, uuid: String, gpsUsed: String, hdop: String, longitude: String, latitude: String, altitude: String, scannedText: String, notes: String) async {
        
        // HDOP within the threshold?
        if Double(hdop) ?? 99.0 <= hdopThreshold {
            // Pass Bluetooth GPS data
            await savePicToFolder(imgFile: image, tripOrRouteName: tripOrRouteName, uuid: uuid, gpsUsed: gpsUsed,
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
                                 scannedText: String, notes: String) async {
        
        do {
            // Save image to Trip's folder
            try _ = FieldWorkImageFile.saveToFolder(imgFile: imgFile, tripOrRouteName: tripOrRouteName, fileNameUUID: uuid)
        } catch {
            print(error.localizedDescription)
            audio.playError()
        }
        
        await createImageCsvFileForTheDay(tripOrRouteName: tripOrRouteName)
        
        
        // Write the pic's info to a .txt file
        do {
            // .txt file header order is uuid, gps, hdop, longitude, latitude, altitude.
            try _ = FieldWorkGPSFile.writePicDataToCsvFile(tripOrRouteName: tripOrRouteName, fileNameUUID: uuid, gpsUsed: gpsUsed, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude, scannedText: scannedText, notes: notes)
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
        let isValid = true
        
        numofmatches = 0
        
        // Remove special characters from user data
        let pattern = "[^A-Za-z0-9.:;\\s_\\-]+"
        self.textNotes = textNotes.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        
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
    
    func resetSnaphotCords() {
        snapshotLatitude = "0"
        snapshotLongitude = "0"
        snapshotAltitude = "0"
        snapshotHorzAccuracy = "9999.99"
    }
}
