//
//  AlertsAndStrings.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23, 2/3/23.
//

import Foundation


// For pop up alerts
struct Article: Identifiable {
    var id: String {title}
    var title: String
    var description: String
}

// Alert struct from https://betterprogramming.pub/effortless-swiftui-camera-d7a74abde37e
public struct AlertError {
    public var title: String = ""
    public var message: String = ""
    public var primaryButtonTitle = "Accept"
    public var secondaryButtonTitle: String?
    public var primaryAction: (() -> ())?
    public var secondaryAction: (() -> ())?
    
    public init(title: String = "", message: String = "", primaryButtonTitle: String = "Accept",
                secondaryButtonTitle: String? = nil, primaryAction: (() -> ())? = nil,
                secondaryAction: (() -> ())? = nil) {
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryAction = secondaryAction
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
