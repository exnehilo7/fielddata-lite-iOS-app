//
//  Models.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.

import Foundation
import CoreLocation
import MapKit
//import UIKit
import SwiftUI


// Model object for html root
class HtmlRootModel: Codable {
    var htmlRoot = "http://covid-samples01.ornl.gov/fielddata-lite"
}

class MapPointSize {
    let size: CGFloat = 35
}

// Model object for SelectAreaView.
class SelectNameModel: Codable, Identifiable {
    var name = ""
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
    var siteId = ""
    var organismName = ""
    var lat = ""
    var long = ""
    
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
    
            try container.encode(siteId, forKey: .siteId)
            try container.encode(organismName, forKey: .organismName)
            try container.encode(lat, forKey: .lat)
            try container.encode(long, forKey: .long)
        }
    
        init() { }
    
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
    
            siteId = try container.decode(String.self, forKey: .siteId)
            organismName = try container.decode(String.self, forKey: .organismName)
            lat = try container.decode(String.self, forKey: .lat)
            long = try container.decode(String.self, forKey: .long)
        }
    
}
extension TempMapPointModel: Codable {
    enum CodingKeys: CodingKey {
        case siteId, organismName, lat, long
    }
}
//class TempMapPointModel_Container: ObservableObject {
//     var TempMapPointModelArray:[TempMapPointModel] = [TempMapPointModel]()
//}

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
    var siteId = ""
    var organismName = ""
    var systemName = ""
    var size: CGFloat = MapPointSize().size
    var highlightColor = Color(white: 0.4745)
}


// ATTEMPTED STRUCT AND CLASS REBUILD:
// Model for map annotations
//struct MapAnnotationItem: Identifiable { //, Sequence, IteratorProtocol {
//
//    let id = UUID()
//
//    var latitude: CGFloat = 0
//    var longitude: CGFloat = 0
//
//    /* When displaying Area or Plot points, the siteId will be the unique
//     ID from the database's table. Otherwise, this variable will be the
//     Routing points' order number. */
//    var siteId = ""
//    var organismName = ""
//    var systemName = ""
//    var size: CGFloat = MapPointSize().size
//
//    var coordinate: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//
//        try container.encode(latitude, forKey: .latitude)
//        try container.encode(longitude, forKey: .longitude)
//        try container.encode(siteId, forKey: .siteId)
//        try container.encode(organismName, forKey: .organismName)
//
//    }
//
//    init() { }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//
//        latitude = try container.decode(CGFloat.self, forKey: .latitude)
//        longitude = try container.decode(CGFloat.self, forKey: .longitude)
//        siteId = try container.decode(String.self, forKey: .siteId)
//        organismName = try container.decode(String.self, forKey: .organismName)
//    }
//
//}
//extension MapAnnotationItem: Codable {
//    enum CodingKeys: String, CodingKey {
//        case latitude = "lat"
//        case longitude = "long"
//        case siteId, organismName//, systemName//, size
//    }
//}
//class MapAnnotationItem_Container: ObservableObject, Codable {
//    var MapAnnotationItemArray:[MapAnnotationItem] = [MapAnnotationItem]()
//
//    enum CodingKeys: CodingKey {
//        case MapAnnotationItemArray
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(MapAnnotationItemArray, forKey: .MapAnnotationItemArray)
//    }
//
//    init() { }
//
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        MapAnnotationItemArray = try container.decode([MapAnnotationItem].self, forKey: .MapAnnotationItemArray)
//    }
//}


// For a starting region in a map
//class StartingRegionModel: Codable, Identifiable {
//    let id = UUID() // DO NOT SET TO MUTABLE
//    var lat = ""
//    var long = ""
//    var zoom = ""
//}

// Model for starting region annotation
//struct RegionAnnotationItem: Identifiable {
//    let id = UUID()
//
//    var latitude: Double
//    var longitude: Double
//    var zoom: Double
//
//    var center: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//    }
//
//    var span: MKCoordinateSpan {
//        MKCoordinateSpan(latitudeDelta: zoom, longitudeDelta: zoom)
//    }
//
//    var region: MKCoordinateRegion {
//        MKCoordinateRegion (
//            center: center,
//            span: span
//        )
//    }
//}




// Teeeest
//class ResponseModel: Codable, Identifiable {
//    var id: String? = ""
//    var type: String? = ""
//}
