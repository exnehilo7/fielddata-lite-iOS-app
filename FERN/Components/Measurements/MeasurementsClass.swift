//
//  MeasurementsClass.swift
//  FERN
//
//  Created by Hopp, Dan on 10/10/24.
//

import Foundation

@Observable class MeasurementsClass {
    
    var score = ""
    var scoreType = "No type"
    var selectedUnit = "cm"
    var currMeasureLabel = 0
    
    /* When adding another measurement type, REMEMBER TO ADD AN INDEX ITEM TO ALL ARRAYS.
     Also, values will be merged into JSON format and saved to a CSV, so avoid problematic
     characters! */
    let measurementLables = ["DBH", "Height"]
    var scoresToSave = ["", ""]
    var unitsToSave = ["cm", "cm"]
    
    // For picker wheel:
    let units = ["cm", "mm", "ft", "in"]
    
    // Create JSON string from measurementLables, scoresToSave, and unitsToSave
    func createScoreJSON() -> String {
        var scoresJSON = "{"
                        
        for (i, element) in measurementLables.enumerated() {
            scoresJSON.append("\"\(element)\": {\"Score\": \"\(scoresToSave[i])\"; \"Unit\": \"\(unitsToSave[i])\"}; ")
        }
        // Axe trailing , and space
        scoresJSON.removeLast()
        scoresJSON.removeLast()
        // Close JSON
        scoresJSON.append("}")
        
        return scoresJSON
    }
    
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
        
        scoresToSave[currMeasureLabel] = score
        unitsToSave[currMeasureLabel] = selectedUnit
       
        // Move to the next score
        currMeasureLabel = currMeasureLabel + dir
        scoreType = measurementLables[currMeasureLabel]
        score = scoresToSave[currMeasureLabel]
        selectedUnit = unitsToSave[currMeasureLabel]
    }
    
    func assignCurrentScoreForSave() {
        // Assign score to current type's variable
        scoresToSave[currMeasureLabel] = score
        unitsToSave[currMeasureLabel] = selectedUnit
    }
    
    func setMeasurementVars() {
        // Pull array's current index value into variables
        scoreType = measurementLables[currMeasureLabel]
        score = scoresToSave[currMeasureLabel]
        selectedUnit = unitsToSave[currMeasureLabel]
    }
    
    func clearMeasurementVars() {
        score = ""
        scoreType = "No type"
        scoresToSave = ["", ""]
        currMeasureLabel = 0
    }
    
}
