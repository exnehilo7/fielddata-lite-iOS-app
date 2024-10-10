//
//  Strings.swift
//  FERN
//
//  Created by Hopp, Dan on 10/10/24.
//

import Foundation
import UIKit


// Get device's ID. NOTE: As of this writing, there is a bug where if an app is deleted and it (or a new version?) is reinstalled, the device UUID will be different than previous.
final class DeviceUUID: Sendable {
    let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? "no_device_uuid"
}

class TextEditorAppend {
    func appendToTextEditor(oldText: String, newText: String) -> String {
        var old = oldText
        let new = newText
        old.append(contentsOf: "\n" + new)
        return old
    }
}

// Regex pattern to remove invalid characters from an image scan
class ScannedTextPattern {
    // Replace " and ' and \ and , with nothing for scanned text
    let pattern = "[^A-Za-z0-9!@#$%&*()\\-_+=.<>;:/?\\s]+"
}

class SearchOrganismName : ObservableObject {
    var organismName = ""
}

class GetFormattedDateStrings {
    
    func getDateString_yyyy_MM_dd() -> String {
        let formatterDate = DateFormatter()
        formatterDate.dateFormat = "yyyy-MM-dd"
        return formatterDate.string(from: Date())
    }
    
    func getTimestampSrting_yyyy_MM_dd_HH_mm_ssSSSx() -> String {
        let formatterDateTime = DateFormatter()
        formatterDateTime.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSx"
        return formatterDateTime.string(from: Date())
    }
}
