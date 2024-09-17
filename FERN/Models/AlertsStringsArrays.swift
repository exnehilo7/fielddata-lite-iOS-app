//
//  AlertsAndStrings.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23, 2/3/23, 9/17/24
//
//  Classes are reference types. Structs are value types.
//  Classes marked with "final" can not be overridden. When you declare a class as being final, no other class can inherit from it. This means a programmer can’t override your methods in order to change your behavior – they need to use your class the way it was written.

import Foundation
import UIKit


// For pop up alerts
struct Article: Identifiable {
    var id: String {title}
    var title: String
    var description: String
}

// Alert struct from https://betterprogramming.pub/effortless-swiftui-camera-d7a74abde37e
public struct AlertError {
    public var title: String = ""
    public var message: String = ""
    public var primaryButtonTitle = "Accept"
    public var secondaryButtonTitle: String?
    public var primaryAction: (() -> ())?
    public var secondaryAction: (() -> ())?
    
    public init(title: String = "", message: String = "", primaryButtonTitle: String = "Accept",
                secondaryButtonTitle: String? = nil, primaryAction: (() -> ())? = nil,
                secondaryAction: (() -> ())? = nil) {
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryAction = secondaryAction
    }
}

// Regex pattern to remove invalid characters from an image scan
class ScannedTextPattern {
    // Replace " and ' and \ and , with nothing for scanned text
    let pattern = "[^A-Za-z0-9!@#$%&*()\\-_+=.<>;:/?\\s]+"
}

class SearchOrganismName : ObservableObject {
    var organismName = ""
}

// Get device's ID. NOTE: As of this writing, there is a bug where if an app is deleted and it (or a new version?) is reinstalled, the device UUID will be different than previous.
final class DeviceUUID: Sendable {
    let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? "no_device_uuid"
}


final struct Measurements : ObservableObject {
    
    var score = ""
    var scoreType = "No type"
    var selectedUnit = "cm"
    var currMeasureLabel = 0
    
    // When adding another measurement type, REMEMBER TO ADD AN INDEX TO ALL ARRAYS:
    let measurementLables = ["DBH", "Height"]
    var scoresToSave = ["", ""]
    var unitsToSave = ["cm", "cm"]
    
    // For picker wheel:
    let units = ["cm", "mm", "ft", "in"]
    
    // Scoring measurement type navigation
    func cycleScoringTypes(forward: Bool) {
           
       let count = measurementLables.count

       if forward {
           // Is end reached?
           if count == currMeasureLabel + 1 {
               // do nothing
           } else {
               exchangeScoreValues(dir: 1)
           }
           
       } else {
           // Is start reached?
           if currMeasureLabel == 0 {
               // do nothing
           } else {
               exchangeScoreValues(dir: -1)
           }
       }
    }
    private func exchangeScoreValues(dir: Int) {
       // Assign score to current type's variable
       scoresToSave[currMeasureLabel] = score
       unitsToSave[currMeasureLabel] = selectedUnit
       
       // Move to the next score
       currMeasureLabel = currMeasureLabel + dir
       scoreType = measurementLables[currMeasureLabel]
       score = scoresToSave[currMeasureLabel]
       selectedUnit = unitsToSave[currMeasureLabel]
    }
    
    func setMeasurementVars(){
        // Pull array's current index value into variables
        scoreType = measurementLables[currMeasureLabel]
        score = scoresToSave[currMeasureLabel]
        selectedUnit = unitsToSave[currMeasureLabel]
    }
    
    func clearMeasurementVars(){
        score = ""
        scoreType = "No type"
        scoresToSave = ["", ""]
    }
    
}
