//
//  FERN-EoS-Bridge.swift
//  FERN
//
//  Created by Hopp, Dan on 3/14/23.
//
// The .swift allows @objc, but when imported in ViewController.m, some of its very first variable definitions are ignored.

import Foundation
import SwiftUI

@objc class GPSFeedViewFactory: NSObject {
    
    @objc static func bridgeGPSFeedUI(latitude: String, longitude: String, altitude: String,
                             xyAccuracy: String, gpsUsed: String) -> UIViewController {
        let gpsFeedView = GPSFeedView(latitude: latitude, longitude: longitude,
                                      altitude: altitude, xyAccuracy: xyAccuracy,
                                      gpsUsed: gpsUsed)
        let hostingController = UIHostingController(rootView: gpsFeedView)
        
        return hostingController
    }
}

