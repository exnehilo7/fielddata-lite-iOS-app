//
//  Classes.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//
// Decodeable syntax error fix help from https://www.hackingwithswift.com/forums/swiftui/trying-to-make-a-observable-object-with-an-array-of-codable-objects-to-be-able-to-reference-it-anywhere-in-my-app/6560

import Foundation

class SearchOrganismName : ObservableObject {
    @Published var organismName = ""
}

class AreaName : ObservableObject {
    @Published var areaName = ""
}

//// Class for SearchByNameView's list
//class SearchByNameModel: Codable, Identifiable, ObservableObject {
//    enum CodingKeys: CodingKey {
//        case id, type, isSelected
//    }
//
//    // Be sure the types match (for each and every item??) what the JSON response is returning
//    @Published var id = ""
//    @Published var type: String? = ""
////    @SomeKindOfBool var wtf: Bool
////    @Published var isSelected: Bool = true
//    @Published var isSelected = ""
//
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        id = try container.decode(String.self, forKey: .id)
//        type = try container.decode(String.self, forKey: .type)
////        isSelected = try container.decode(Bool.self, forKey: .isSelected)
//        isSelected = try container.decode(String.self, forKey: .isSelected)
//    }
//
//    init(){
//
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(type, forKey: .type)
//        try container.encode(isSelected, forKey: .isSelected)
//    }
//}
//
//// An array of Search By Name items from the query return
//class PlotList: ObservableObject{
//    @Published var plotList = [SearchByNameModel]()
//}



//@propertyWrapper
//struct SomeKindOfBool: Decodable {
//    var wrappedValue: Bool
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//
//        //Handle String value
//        if let stringValue = try? container.decode(String.self) {
//            switch stringValue.lowercased() {
//            case "false", "no", "0": wrappedValue = false
//            case "true", "yes", "1": wrappedValue = true
//            default: throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expect true/false, yes/no or 0/1 but`\(stringValue)` instead")
//            }
//        }
//
//        //Handle Int value
//        else if let intValue = try? container.decode(Int.self) {
//            switch intValue {
//            case 0: wrappedValue = false
//            case 1: wrappedValue = true
//            default: throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expect `0` or `1` but found `\(intValue)` instead")
//            }
//        }
//
//        //Handle Int value
//        else if let doubleValue = try? container.decode(Double.self) {
//            switch doubleValue {
//            case 0: wrappedValue = false
//            case 1: wrappedValue = true
//            default: throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expect `0` or `1` but found `\(doubleValue)` instead")
//            }
//        }
//
//        else {
//            wrappedValue = try container.decode(Bool.self)
//        }
//    }
//}
