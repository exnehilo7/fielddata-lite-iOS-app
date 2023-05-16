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
