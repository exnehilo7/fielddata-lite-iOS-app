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

// Model object for map points
class MapPointModel: Codable, Identifiable { //ObservableObject
    var siteId = ""
    var organismName = ""
    var geoPoint = ""
}

// Model for map annotations
struct MapAnnotationItem: Identifiable {
    var coordinate: CLLocationCoordinate2D
    let id = UUID()
//    var color: Color?
//    var tint: Color { color ?? .red }
}

// Teeeest
class ResponseModel: Codable, Identifiable {
    var id: String? = ""
    var type: String? = ""
//    var isSelected: String? = ""
}
