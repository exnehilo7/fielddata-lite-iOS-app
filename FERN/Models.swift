//
//  Models.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.

import Foundation
import CoreLocation
//import UIkit // Needed for MapAnnotationItem's color. Apparently I need to change some swiftc options
                // to build the project against proper sdk and target?

// Model object for html root
class HtmlRootModel: Codable {
    var htmlRoot = "http://covid-samples01.ornl.gov/fielddata-lite"
}

// Model object for SelectAreaView
class SelectLocationModel: Codable, Identifiable {
    var name = ""
}


//class MapPointModel: Identifiable, ObservableObject{
//
//    var annotationItems = [MapAnnotationItem]()
//
//    var siteId = ""
//    var organismName = ""
//    var coordinate: CLLocationCoordinate2D
//    let id = UUID()
//
//    init(siteId: String = "", organismName: String = "", coordinate: CLLocationCoordinate2D) {
//        self.siteId = siteId
//        self.organismName = organismName
//        self.coordinate = coordinate
//
//        annotationItems.append(MapAnnotationItem(coordinate: coordinate, siteId: siteId, organismName: organismName))
//
//    }
//}

// temp llist for display and insertion into MapAnnotationItem
class TempMapPointModel: Codable, Identifiable {
    var siteId = ""
    var organismName = ""
    var lat = ""
    var long = ""
}

// Model for map annotations
struct MapAnnotationItem: Identifiable {
    
    var coordinate: CLLocationCoordinate2D
    let id = UUID()
    
    // try more vars
    var siteId = ""
    var organismName = ""
}

// MAY NEVER USE OBSERVABLE IDENTIFIABLE DECODABLE OBJECT??
class Temp_MapPointModel_ObsvObj: ObservableObject, Identifiable {  // Identifiable,
    
    let id = UUID()
    
    var siteId = ""
    var organismName = ""
    var geoPoint = ""
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(siteId, forKey: .siteId)
        try container.encode(organismName, forKey: .organismName)
        try container.encode(geoPoint, forKey: .geoPoint)
    }
    
    init() { }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        siteId = try container.decode(String.self, forKey: .siteId)
        organismName = try container.decode(String.self, forKey: .organismName)
        geoPoint = try container.decode(String.self, forKey: .geoPoint)
    }
}
extension Temp_MapPointModel_ObsvObj: Codable {
    enum CodingKeys: CodingKey {
        case siteId, organismName, geoPoint
    }
}
class Temp_MapPointModel_ObsvObj_Container: ObservableObject {
    @Published var objects = [Temp_MapPointModel_ObsvObj]()
}

// Teeeest
class ResponseModel: Codable, Identifiable {
    var id: String? = ""
    var type: String? = ""
//    var isSelected: String? = ""
}
