//
//  Classes.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//
// Decodeable syntax error fix help from https://www.hackingwithswift.com/forums/swiftui/trying-to-make-a-observable-object-with-an-array-of-codable-objects-to-be-able-to-reference-it-anywhere-in-my-app/6560

import Foundation

// Class for SearchByNameView's list
class SearchByNameModel: Codable, Identifiable, ObservableObject {
    enum CodingKeys: CodingKey {
        case testId, type, isSelected
    }
    
    // Be sure the types match what the JSON response is returning
    @Published var testId = ""
    @Published var type: String? = ""
    @Published var isSelected = true
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        testId = try container.decode(String.self, forKey: .testId)
        type = try container.decode(String.self, forKey: .type)
        isSelected = try container.decode(Bool.self, forKey: .isSelected)
    }

    init(){

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(testId, forKey: .testId)
        try container.encode(type, forKey: .type)
        try container.encode(isSelected, forKey: .isSelected)
    }
}

class PlotList: ObservableObject{
    @Published var plotList = [SearchByNameModel]()
}


// Class object for map points
class MapPointList: ObservableObject {
    var siteId = ""
    var geoPoint = ""
}
