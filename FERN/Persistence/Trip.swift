//
//  Trip.swift
//  FERN
//
//  Created by Hopp, Dan on 1/19/24.
//

import Foundation
import SwiftData

@Model
class SDTrip {
    @Attribute(.unique) var name: String
    var isComplete: Bool
    var allFilesUploaded: Bool
    @Relationship(deleteRule: .cascade) var files: [TripFile]?
    
    init(name: String = "", isComplete: Bool = false, allFilesUploaded: Bool = false, files: [TripFile] = []){
        self.name = name
        self.isComplete = isComplete
        self.allFilesUploaded = allFilesUploaded
        self.files = files
    }
}

@Model
class TripFile { // 14-MAR-2024: No longer required. (Removing will require deletion and reinstallation of the FERN app, unless SwiftData has been fixed for version migration)
    
    var fileName: String
    var isUploaded: Bool
    
    init(fileName: String, isUploaded: Bool = false) {
        self.fileName = fileName
        self.isUploaded = isUploaded
    }
}
