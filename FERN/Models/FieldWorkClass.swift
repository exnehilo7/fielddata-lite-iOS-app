//
//  FieldWorkClass.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//
//  Create a text file for a trip and append GPS plus other data.

import Foundation
import UIKit


// File create and append from https://stackoverflow.com/questions/27327067/append-text-or-data-to-text-file-in-swift
class FieldWorkGPSFile {
    
    static var gpsFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory
    }
    
    static func log(tripOrRouteName: String, uuid: String, gpsUsed: String, hdop: String, longitude: String, latitude: String, altitude: String,
                    scannedText: String, notes: String) throws -> Bool {
        guard let gpsFile = gpsFile else {
            return false
        }

        var filePath: URL
        
        // Make the file name date_tripName_deviceUUID.txt
        let formatterDate = DateFormatter()
        formatterDate.dateFormat = "yyyy-MM-dd"
        let dateString = formatterDate.string(from: Date())
        // Use the unique device ID for the text file name and the folder path.
        if let deviceUuid = UIDevice.current.identifierForVendor?.uuidString
        {
            let fileName = "\(dateString)_\(tripOrRouteName)_\(deviceUuid).txt"
            let path = gpsFile.appendingPathComponent("\(deviceUuid)/trips/\(tripOrRouteName)")
            do {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            } catch {}
            filePath = path.appendingPathComponent(fileName)
        } else {
            let fileName = "\(dateString)_No_Device_UUID.txt"
            let path = gpsFile.appendingPathComponent("no_device_uuid/trips/\(tripOrRouteName)")
            do {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            } catch {}
            filePath = path.appendingPathComponent(fileName)
        }
        
        
            let formatterDateTime = DateFormatter()
            formatterDateTime.dateFormat = "yyyy-MM-dd HH:mm:ssx"
            let timestamp = formatterDateTime.string(from: Date())
            let message = "\(uuid),\(gpsUsed),\(hdop),\(longitude),\(latitude),\(altitude),\(scannedText),\(timestamp),\(notes)"
            guard let data = (message + "\n").data(using: String.Encoding.utf8) else { return false}
        
            if FileManager.default.fileExists(atPath: filePath.path) {
                if uuid.count > 0 {
                    if let fileHandle = try? FileHandle(forWritingTo: filePath) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                }
            } else {
                if uuid.count < 1 {
                    // Create header
                    guard let headerData = ("pic_uuid,gps,hdop,longitude,latitude,altitude,scanned_text,line_written_on,notes\n").data(using: String.Encoding.utf8) else { return false}
                    try? headerData.write(to: filePath, options: .atomicWrite)
                }
            }
        return true
    }
}

class FieldWorkImageFile {
    
    static var gpsFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory
    }
    
    static func saveToFolder(imgFile: UIImage, tripOrRouteName: String, uuid: String, gpsUsed: String,
                             hdop: String, longitude: String, latitude: String, altitude: String) throws -> Bool {
        guard let gpsFile = gpsFile else {
            return false
        }

        var filePath: URL
        
        let fileName = "\(uuid).heic"
        // Use the unique device ID for the text file name and the folder path.
        if let deviceUuid = UIDevice.current.identifierForVendor?.uuidString
        {
            let path = gpsFile.appendingPathComponent("\(deviceUuid)/trips/\(tripOrRouteName)")
            do {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            } catch {}
            filePath = path.appendingPathComponent(fileName)
        } else {
            let path = gpsFile.appendingPathComponent("no_device_uuid/trips/\(tripOrRouteName)")
            do {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            } catch {}
            filePath = path.appendingPathComponent(fileName)
        }
        
        print(filePath)
    
            do {
                if let imageData = imgFile.jpegData(compressionQuality: 1) {
                    try imageData.write(to: filePath)
                }
            } catch {print (error)}
        return true
    }
}
