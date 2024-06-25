//
//  FieldWorkClass.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//
//  Create a text file for a trip and append GPS plus other data.

import Foundation
import UIKit


class GetFormattedDateStrings {
    
    func getDateString_yyyy_MM_dd() -> String {
        let formatterDate = DateFormatter()
        formatterDate.dateFormat = "yyyy-MM-dd"
        return formatterDate.string(from: Date())
    }
    
    func getTimestampSrting_yyyy_MM_dd_HH_mm_ssx() -> String {
        let formatterDateTime = DateFormatter()
        formatterDateTime.dateFormat = "yyyy-MM-dd HH:mm:ssx"
        return formatterDateTime.string(from: Date())
    }
}

class ProcessTextfile {
    
    func createPath(path: URL, fileName: String) -> URL {
        do {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        } catch {}
        return path.appendingPathComponent(fileName)
    }
    
    // Create file if not exists, else append data to file
    func writeToTextfile(data: Data, filePath: URL, uuid: String, header: String) -> Bool {
        if FileManager.default.fileExists(atPath: filePath.path) {
            if uuid.count > 0 {
                if let fileHandle = try? FileHandle(forWritingTo: filePath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                    return true
                }
            }
        } else {
            if uuid.count < 1 {
                // Create header
                guard let headerData = header.data(using: String.Encoding.utf8) else { return false}
                try? headerData.write(to: filePath, options: .atomicWrite)
                return true
            }
        }
        return false
    }
}


// File create and append from https://stackoverflow.com/questions/27327067/append-text-or-data-to-text-file-in-swift
class FieldWorkGPSFile {
    
    static var gpsDir: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory
    }
    
    static func log(tripOrRouteName: String, uuid: String, gpsUsed: String, hdop: String, longitude: String, latitude: String, altitude: String,
                    scannedText: String, notes: String) throws -> Bool {
        guard let gpsDir = gpsDir else {
            return false
        }

        var filePath: URL
        
        // Make the file name date_tripName_deviceUUID.txt
        let dateString = GetFormattedDateStrings().getDateString_yyyy_MM_dd()
        // Use the unique device ID for the text file name and the folder path.
        if let deviceUuid = UIDevice.current.identifierForVendor?.uuidString {
            let fileName = "\(dateString)_\(tripOrRouteName)_\(deviceUuid).txt"
            let path = gpsDir.appendingPathComponent("\(deviceUuid)/trips/\(tripOrRouteName)")
            filePath = ProcessTextfile().createPath(path: path, fileName: fileName)
        } else {
            let fileName = "\(dateString)_\(tripOrRouteName)_No_Device_UUID.txt"
            let path = gpsDir.appendingPathComponent("no_device_uuid/trips/\(tripOrRouteName)")
            filePath = ProcessTextfile().createPath(path: path, fileName: fileName)
        }
        
        
        let timestamp = GetFormattedDateStrings().getTimestampSrting_yyyy_MM_dd_HH_mm_ssx()
        let message = "\(uuid),\(gpsUsed),\(hdop),\(longitude),\(latitude),\(altitude),\(scannedText),\(timestamp),\(notes)"
        guard let data = (message + "\n").data(using: String.Encoding.utf8) else { return false}
    
        return ProcessTextfile().writeToTextfile(data: data, filePath: filePath, uuid: uuid, header: "pic_uuid,gps,hdop,longitude,latitude,altitude,scanned_text,line_written_on,notes\n")
    }
}

class FieldWorkImageFile {
    
    static var imageDir: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory
    }
    
    static func saveToFolder(imgFile: UIImage, tripOrRouteName: String, uuid: String, gpsUsed: String,
                             hdop: String, longitude: String, latitude: String, altitude: String) throws -> Bool {
        guard let imageDir = imageDir else {
            return false
        }

        var filePath: URL
        
        let fileName = "\(uuid).heic"
        // Use the unique device ID for the text file name and the folder path.
        if let deviceUuid = UIDevice.current.identifierForVendor?.uuidString {
            let path = imageDir.appendingPathComponent("\(deviceUuid)/trips/\(tripOrRouteName)")
            filePath = ProcessTextfile().createPath(path: path, fileName: fileName)
        } else {
            let path = imageDir.appendingPathComponent("no_device_uuid/trips/\(tripOrRouteName)")
            filePath = ProcessTextfile().createPath(path: path, fileName: fileName)
        }
    
            do {
                if let imageData = imgFile.jpegData(compressionQuality: 1) {
                    try imageData.write(to: filePath)
                }
            } catch {print (error)}
        return true
    }
}

class FieldWorkScoringFile {
    
    static var scoringDir: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory
    }
    
    static func writeScoreToTextFile(tripOrRouteName: String, uuid: String, organismName: String, score: String) throws -> Bool {
        guard let scoringDir = scoringDir else {
            return false
        }

        var filePath: URL
        
        // Make the file name date_tripName_deviceUUID.txt
        let dateString = GetFormattedDateStrings().getDateString_yyyy_MM_dd()
        // Use the unique device ID for the text file name and the folder path.
        if let deviceUuid = UIDevice.current.identifierForVendor?.uuidString {
            let fileName = "\(dateString)_\(tripOrRouteName)_\(deviceUuid)_Scoring.txt"
            let path = scoringDir.appendingPathComponent("\(deviceUuid)/trips/\(tripOrRouteName)")
            filePath = ProcessTextfile().createPath(path: path, fileName: fileName)
        } else {
            let fileName = "\(dateString)_No_Device_UUID_Scoring.txt"
            let path = scoringDir.appendingPathComponent("no_device_uuid/trips/\(tripOrRouteName)")
            filePath = ProcessTextfile().createPath(path: path, fileName: fileName)
        }
        
        
        let timestamp = GetFormattedDateStrings().getTimestampSrting_yyyy_MM_dd_HH_mm_ssx()
        let message = "\(timestamp),\(organismName),\(score)"
        guard let data = (message + "\n").data(using: String.Encoding.utf8) else { return false}
    
        return ProcessTextfile().writeToTextfile(data: data, filePath: filePath, uuid: uuid, header: "line_written_on,organism_name,score\n")
    }
}
