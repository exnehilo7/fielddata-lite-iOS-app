//
//  Models.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.

import Foundation
import CoreLocation
import MapKit
import SwiftUI


// Model object for SelectAreaView.
class SelectNameModel: Codable, Identifiable {
    var name = ""
}

struct Article: Identifiable {
    var id: String {title}
    var title: String
    var description: String
}

// Model for SelectNoteView
struct SelectNoteModel: Codable, Identifiable, Hashable {
    var id = ""
    var note = ""
    var confirmDelete = false
    
    enum CodingKeys: CodingKey {
        case id, note
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(note, forKey: .note)
    }

    init() { }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        note = try container.decode(String.self, forKey: .note)
    }
    
}

// Model for route total distance report
struct RouteTotalDistanceModel: Identifiable {
    let id = UUID()
    var routeName = ""
    var totalDistanceKm = ""
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(routeName, forKey: .routeName)
        try container.encode(totalDistanceKm, forKey: .totalDistanceKm)

    }

    init() { }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        routeName = try container.decode(String.self, forKey: .routeName)
        totalDistanceKm = try container.decode(String.self, forKey: .totalDistanceKm)

    }
    
}
extension RouteTotalDistanceModel: Codable {
    enum CodingKeys: String, CodingKey {
        case routeName = "route_name"
        case totalDistanceKm = "total_distance_km"
    }
}


// temp list for display and insertion into MapAnnotationItem
struct TempMapPointModel: Identifiable {
    let id = UUID() // if changed to class, DO NOT SET TO MUTABLE
    var routeID = ""
    var pointOrder = ""
    var organismName = ""
    var lat = ""
    var long = ""
    var r = ""
    var g = ""
    var b = ""
    
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
    
            try container.encode(routeID, forKey: .routeID)
            try container.encode(pointOrder, forKey: .pointOrder)
            try container.encode(organismName, forKey: .organismName)
            try container.encode(lat, forKey: .lat)
            try container.encode(long, forKey: .long)
            try container.encode(r, forKey: .r)
            try container.encode(g, forKey: .g)
            try container.encode(b, forKey: .b)
        }
    
        init() { }
    
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
    
            routeID = try container.decode(String.self, forKey: .routeID)
            pointOrder = try container.decode(String.self, forKey: .pointOrder)
            organismName = try container.decode(String.self, forKey: .organismName)
            lat = try container.decode(String.self, forKey: .lat)
            long = try container.decode(String.self, forKey: .long)
            r = try container.decode(String.self, forKey: .r)
            g = try container.decode(String.self, forKey: .g)
            b = try container.decode(String.self, forKey: .b)
        }
    
}
extension TempMapPointModel: Codable {
    enum CodingKeys: CodingKey {
        case routeID, pointOrder, organismName, lat, long, r, g, b
    }
}

// temp model for distance and bearing return from PHP POST
struct TempDistanceAndBearingModel: Identifiable {
    let id = UUID() // if changed to class, DO NOT SET TO MUTABLE
    var distance = ""
    var bearing = ""
    
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
    
            try container.encode(distance, forKey: .distance)
            try container.encode(bearing, forKey: .bearing)
        }
    
        init() { }
    
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
    
            distance = try container.decode(String.self, forKey: .distance)
            bearing = try container.decode(String.self, forKey: .bearing)
        }
    
}
extension TempDistanceAndBearingModel: Codable {
    enum CodingKeys: CodingKey {
        case distance, bearing
    }
}

// Model for map annotations
struct MapAnnotationItem: Identifiable {
    let id = UUID()
    var latitude: CGFloat
    var longitude: CGFloat
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /* When displaying Area or Plot points, the siteId will be the unique
     ID from the database's table. Otherwise, this variable will be the
     Routing points' order number. */
    var routeID = ""
    var pointOrder = ""
    var organismName = ""
    var systemName = ""
    var size: CGFloat = MapPointSize().size
    var highlightColor = Color(red: 0, green: 0, blue: 0)
}

class MapPointSize {
    let size: CGFloat = 10
}
