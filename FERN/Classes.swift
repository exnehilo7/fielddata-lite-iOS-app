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

class SearchOrganismName : ObservableObject {
    var organismName = ""
}

// Core location functionality from https://www.mongodb.com/developer/products/realm/realm-swiftui-maps-location/
class LocationHelper: NSObject, ObservableObject {

    static let shared = LocationHelper()
    static let DefaultLocation = CLLocationCoordinate2D(latitude: 35.93212, longitude: -84.31022)
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
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: Date())
        let fileName = "\(dateString).txt"
        return documentsDirectory.appendingPathComponent(fileName)
    }

    static func log(_ message: String) throws -> Bool {
        guard let gpsFile = gpsFile else {
            return false
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        guard let data = (timestamp + ": " + message + "\n").data(using: String.Encoding.utf8) else { return false}

        if FileManager.default.fileExists(atPath: gpsFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: gpsFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: gpsFile, options: .atomicWrite)
        }
        
        return true
    }
}
