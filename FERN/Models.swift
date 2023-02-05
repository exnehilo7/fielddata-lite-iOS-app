//
//  Models.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.

import Foundation

// Model object for SelectAreaView
class SelectLocationModel: Codable, Identifiable {
    var name = ""
}

// Model object for map points
class MapPointModel: ObservableObject {
    var siteId = ""
    var geoPoint = ""
}

// Teeeest
class ResponseModel: Codable, Identifiable {
    var id: String? = ""
    var type: String? = ""
//    var isSelected: String? = ""
}
