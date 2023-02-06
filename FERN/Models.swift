//
//  Models.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.

import Foundation

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

// Teeeest
class ResponseModel: Codable, Identifiable {
    var id: String? = ""
    var type: String? = ""
//    var isSelected: String? = ""
}
