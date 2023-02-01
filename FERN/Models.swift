//
//  Models.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.

import Foundation

class ResponseModel: Codable, Identifiable {
    // Be sure the types match what the JSON response is returning
    var id: String? = ""
    var type: String? = ""
}
