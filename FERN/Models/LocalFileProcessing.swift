//
//  LocalFileProcessing.swift
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
    
    func getTimestampSrting_yyyy_MM_dd_HH_mm_ssSSSx() -> String {
        let formatterDateTime = DateFormatter()
        formatterDateTime.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSx"
        return formatterDateTime.string(from: Date())
    }
}

class ProcessTextfile {
    
    static func createPath(path: URL, fileName: String) -> URL {
        do {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        } catch {}
        return path.appendingPathComponent(fileName)
    }
    
    // Create file if not exists, else append data to file
    static func writeToTextfile(data: Data, filePath: URL, fileNameUUID: String, header: String) -> Bool {
        if FileManager.default.fileExists(atPath: filePath.path) {
            if fileNameUUID.count > 0 {
                if let fileHandle = try? FileHandle(forWritingTo: filePath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                    return true
                }
            }
        } else {
            if fileNameUUID.count < 1 {
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
    
    static func writePicDataToTxtFile(tripOrRouteName: String, fileNameUUID: String, gpsUsed: String, hdop: String, longitude: String, latitude: String, altitude: String,
                    scannedText: String, notes: String) throws -> Bool {
        
        let timestamp = GetFormattedDateStrings().getTimestampSrting_yyyy_MM_dd_HH_mm_ssSSSx()
        let dateString = GetFormattedDateStrings().getDateString_yyyy_MM_dd()
        let fileName = "\(dateString)_\(tripOrRouteName)_\(DeviceUUID().deviceUUID).csv"
        
        return try CreateOrWriteToFile.createOrWriteToFile(tripOrRouteName: tripOrRouteName, fileNameUUID: fileNameUUID, fileName: fileName, folderName: "metadata", message: "\(fileNameUUID),\(gpsUsed),\(hdop),\(longitude),\(latitude),\(altitude),\(scannedText),\(timestamp),\(notes)", header: "pic_uuid,gps,hdop,longitude,latitude,altitude,scanned_text,line_written_on,notes\n")
        
//        guard let gpsDir = DocumentsDirectory.dir else {
//            return false
//        }
//
//        var filePath: URL
//
//        // Make the file name date_tripName_deviceUUID.txt
//        let dateString = GetFormattedDateStrings().getDateString_yyyy_MM_dd()
//        let fileName = "\(dateString)_\(tripOrRouteName)_\(DeviceUUID().deviceUUID).csv"
//        let path = gpsDir.appendingPathComponent("\(DeviceUUID().deviceUUID)/trips/\(tripOrRouteName)/metadata")
//        filePath = ProcessTextfile.createPath(path: path, fileName: fileName)
//
//        let timestamp = GetFormattedDateStrings().getTimestampSrting_yyyy_MM_dd_HH_mm_ssSSSx()
//        let message = "\(uuid),\(gpsUsed),\(hdop),\(longitude),\(latitude),\(altitude),\(scannedText),\(timestamp),\(notes)"
//        guard let data = (message + "\n").data(using: String.Encoding.utf8) else { return false}
//
//        return ProcessTextfile.writeToTextfile(data: data, filePath: filePath, uuid: uuid, header: "pic_uuid,gps,hdop,longitude,latitude,altitude,scanned_text,line_written_on,notes\n")
    }
}

class FieldWorkImageFile {
    
    static func saveToFolder(imgFile: UIImage, tripOrRouteName: String, fileNameUUID: String, gpsUsed: String,
                             hdop: String, longitude: String, latitude: String, altitude: String) throws -> Bool {
        guard let imageDir = DocumentsDirectory.dir else {
            return false
        }

        var filePath: URL
        
        let fileName = "\(fileNameUUID).heic"
        let path = imageDir.appendingPathComponent("\(DeviceUUID().deviceUUID)/trips/\(tripOrRouteName)/images")
        filePath = ProcessTextfile.createPath(path: path, fileName: fileName)
    
            do {
                if let imageData = imgFile.jpegData(compressionQuality: 1) {
                    try imageData.write(to: filePath)
                }
            } catch {print (error)}
        return true
    }
}

class FieldWorkScoringFile {
    
    static func writeScoreToCSVFile(tripOrRouteName: String, fileNameUUID: String, organismName: String, score: String) throws -> Bool {
        
        let timestamp = GetFormattedDateStrings().getTimestampSrting_yyyy_MM_dd_HH_mm_ssSSSx()
        let dateString = GetFormattedDateStrings().getDateString_yyyy_MM_dd()
        let fileName = "\(dateString)_\(tripOrRouteName)_\(DeviceUUID().deviceUUID)_Scoring.csv"
        
        return try CreateOrWriteToFile.createOrWriteToFile(tripOrRouteName: tripOrRouteName, fileNameUUID: fileNameUUID, fileName: fileName, folderName: "scoring", message: "\(timestamp),\(organismName),\(score)", header: "line_written_on,organism_name,score\n")
        
//        guard let scoringDir = DocumentsDirectory.dir else {
//            return false
//        }
//
//        var filePath: URL
//
//        let dateString = GetFormattedDateStrings().getDateString_yyyy_MM_dd()
//        let fileName = "\(dateString)_\(tripOrRouteName)_\(DeviceUUID().deviceUUID)_Scoring.csv"
//        let path = scoringDir.appendingPathComponent("\(DeviceUUID().deviceUUID)/trips/\(tripOrRouteName)/scoring")
//        filePath = ProcessTextfile.createPath(path: path, fileName: fileName)
//
//        let timestamp = GetFormattedDateStrings().getTimestampSrting_yyyy_MM_dd_HH_mm_ssSSSx()
//        let message = "\(timestamp),\(organismName),\(score)"
//        guard let data = (message + "\n").data(using: String.Encoding.utf8) else { return false}
//
//        return ProcessTextfile.writeToTextfile(data: data, filePath: filePath, uuid: uuid, header: "line_written_on,organism_name,score\n")
    }
}

class UploadHistoryFile {
    
    static func writeUploadToTextFile(tripOrRouteName: String, fileNameUUID: String, fileName: String) async throws -> Bool {
        
        let fileSaveName = "\(tripOrRouteName)_\(DeviceUUID().deviceUUID)_Upload_History.txt"
        
        return try CreateOrWriteToFile.createOrWriteToFile(tripOrRouteName: tripOrRouteName, fileNameUUID: fileNameUUID, fileName: fileSaveName, folderName: "upload_history", message: "\(fileName)", header: "file_name\n")
    }
    
}

class DocumentsDirectory {
    static var dir: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory
    }
}

class CreateOrWriteToFile {
    static func createOrWriteToFile (tripOrRouteName: String, fileNameUUID: String, fileName: String, folderName: String, message: String, header: String) throws -> Bool {
        
        guard let dir = DocumentsDirectory.dir else {
            return false
        }
        
        var filePath: URL
        
        let path = dir.appendingPathComponent("\(DeviceUUID().deviceUUID)/trips/\(tripOrRouteName)/\(folderName)")
        filePath = ProcessTextfile.createPath(path: path, fileName: fileName)
        
        let msg = "\(message)"
        guard let data = (msg + "\n").data(using: String.Encoding.utf8) else { return false}
    
        return ProcessTextfile.writeToTextfile(data: data, filePath: filePath, fileNameUUID: fileNameUUID, header: "\(header)")
    }
}
