//
//  Classes.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//
// Decodeable syntax error fix help from https://www.hackingwithswift.com/forums/swiftui/trying-to-make-a-observable-object-with-an-array-of-codable-objects-to-be-able-to-reference-it-anywhere-in-my-app/6560

import Foundation
import CoreLocation

class SearchOrganismName : ObservableObject {
    @Published var organismName = ""
}

// Core location functionality from https://www.mongodb.com/developer/products/realm/realm-swiftui-maps-location/
class LocationHelper: NSObject, ObservableObject {

    static let shared = LocationHelper()
    static let DefaultLocation = CLLocationCoordinate2D(latitude: 35.93212, longitude: -84.31022)

    static var currentLocation: CLLocationCoordinate2D {
        guard let location = shared.locationManager.location else {
            return DefaultLocation
        }
        return location.coordinate
    }

    private let locationManager = CLLocationManager()

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
}

extension LocationHelper: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location manager changed the status: \(status)")
    }
}


// JSON response decoding help from https://www.hackingwithswift.com/quick-start/concurrency/how-to-download-json-from-the-internet-and-decode-it-into-any-codable-type
extension URLSession {
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        from url: URL,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .deferredToData,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
    ) async throws  -> T {
        let (data, _) = try await data(from: url)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dataDecodingStrategy = dataDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy

        let decoded = try decoder.decode(T.self, from: data)
        return decoded
    }
}
