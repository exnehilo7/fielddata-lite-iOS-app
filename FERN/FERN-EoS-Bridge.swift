//
//  FERN-EoS-Bridge.swift
//  FERN
//
//  Created by Hopp, Dan on 3/14/23.
//

import Foundation
import SwiftUI

@objc class GPSFeedViewFactory: NSObject {
    
    @objc static func create(text: String) -> UIViewController {
        let gpsFeedView = GPSFeedView(latitude: text, longitude: text, altitude: text, xyAccuracy: text, gpsUsed: text)
        let hostingController = UIHostingController(rootView: gpsFeedView)
        
        return hostingController
    }
}

/*
 @State var latitude: String
 @State var longitude: String
 @State var altitude: String
 @State var xyAccuracy: String
 @State var gpsUsed: String
 */
