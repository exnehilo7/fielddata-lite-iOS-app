//
//  CoreLocationClass.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//

import Foundation
import CoreLocation


// Core location functionality from https://www.mongodb.com/developer/products/realm/realm-swiftui-maps-location/
//class LocationHelper: NSObject, ObservableObject {
@Observable class LocationHelper: NSObject, ObservableObject {

    static let shared = LocationHelper()
    static let DefaultLocation = CLLocationCoordinate2D(latitude: 1.1, longitude: 1.1)
    var lastLocation: CLLocation?
//    @Published var lastLocation: CLLocation?

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
        print("Core location started.")
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
