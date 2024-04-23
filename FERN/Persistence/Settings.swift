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
    
    init(databaseURL: String = "https://127.0.0.1/folder/folder", uploadScriptURL: String = "https://127.0.0.1/folder/folder/file.php") {
        self.databaseURL = databaseURL
        self.uploadScriptURL = uploadScriptURL
    }
}
