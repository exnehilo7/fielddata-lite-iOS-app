//
//  Classes.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//
// Decodeable syntax error fix help from https://www.hackingwithswift.com/forums/swiftui/trying-to-make-a-observable-object-with-an-array-of-codable-objects-to-be-able-to-reference-it-anywhere-in-my-app/6560

import Foundation
import CoreLocation
import MapKit
import UIKit

class SearchOrganismName : ObservableObject {
    var organismName = ""
}

// Core location functionality from https://www.mongodb.com/developer/products/realm/realm-swiftui-maps-location/
class LocationHelper: NSObject, ObservableObject {

    static let shared = LocationHelper()
    static let DefaultLocation = CLLocationCoordinate2D(latitude: 1.1, longitude: 1.1)
    @Published var lastLocation: CLLocation?

    static var currentLocation: CLLocationCoordinate2D {
        guard let location = shared.manager.location else {
            return DefaultLocation
        }
        return location.coordinate
    }

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingDefaultCoreLocation(){
        manager.stopUpdatingLocation()
    }
    
    func startUpdatingDefaultCoreLocation(){
        manager.startUpdatingLocation()
    }
}

extension LocationHelper: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {return}
        lastLocation = location
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location manager changed the status: \(status)")
    }
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


// File create and append from https://stackoverflow.com/questions/27327067/append-text-or-data-to-text-file-in-swift
class FieldWorkGPSFile {
    
    static var gpsFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory
    }
    
    static func log(tripName: String, uuid: String, gps: String, hdop: String, longitude: String, latitude: String, altitude: String) throws -> Bool {
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
            let fileName = "\(dateString)_\(tripName)_\(deviceUuid).txt"
            let path = gpsFile.appendingPathComponent("\(deviceUuid)/trips/\(tripName)")
            do {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            } catch {}
            filePath = path.appendingPathComponent(fileName)
        } else {
            let fileName = "\(dateString)_No_Device_UUID.txt"
            let path = gpsFile.appendingPathComponent("no_device_uuid/trips/\(tripName)")
            do {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            } catch {}
            filePath = path.appendingPathComponent(fileName)
        }
        
        
            let formatterDateTime = DateFormatter()
            formatterDateTime.dateFormat = "yyyy-MM-dd HH:mm:ssx"
            let timestamp = formatterDateTime.string(from: Date())
            let message = "\(uuid),\(gps),\(hdop),\(longitude),\(latitude),\(altitude),\(timestamp)"
            guard let data = (message + "\n").data(using: String.Encoding.utf8) else { return false}
            
            print(filePath)
        
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
                    guard let headerData = ("pic_uuid,gps,hdop,longitude,latitude,altitude,line_written_on\n").data(using: String.Encoding.utf8) else { return false}
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
    
    static func saveToFolder(imgFile: UIImage, tripName: String, uuid: String, gps: String, hdop: String, longitude: String, latitude: String, altitude: String) throws -> Bool {
        guard let gpsFile = gpsFile else {
            return false
        }

        var filePath: URL
        
        let fileName = "\(uuid).heif"
        // Use the unique device ID for the text file name and the folder path.
        if let deviceUuid = UIDevice.current.identifierForVendor?.uuidString
        {
            let path = gpsFile.appendingPathComponent("\(deviceUuid)/trips/\(tripName)")
            do {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            } catch {}
            filePath = path.appendingPathComponent(fileName)
        } else {
            let path = gpsFile.appendingPathComponent("no_device_uuid/trips/\(tripName)")
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
