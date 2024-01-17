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
    
    init(databaseURL: String = "http://1.1.1.1/folder/folder", uploadScriptURL: String = "http://1.1.1.1/folder/folder/file.php") {
        self.databaseURL = databaseURL
        self.uploadScriptURL = uploadScriptURL
    }
}
