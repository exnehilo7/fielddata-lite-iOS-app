//
//  Settings.swift
//  FERN
//
//  Created by Hopp, Dan on 1/16/24.
//

import Foundation
import SwiftData


@Model
class Settings {
    var databaseURL: String
    var uploadScriptURL: String
    
    init(databaseURL: String = "http://103.72.77.233/ORNL/fielddata-lite", uploadScriptURL: String = "http://103.72.77.233/ORNL/fielddata-lite/php/upload.php") {
        self.databaseURL = databaseURL
        self.uploadScriptURL = uploadScriptURL
    }
}
