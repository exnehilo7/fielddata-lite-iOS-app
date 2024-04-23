//
//  CameraServiceEnums.swift
//  FERN
//
//  Created by Hopp, Dan on 5/17/23. Code from https://github.com/rorodriguez116/SwiftCamera/blob/main/SwiftCamera/CameraService%2BEnums.swift
//

import Foundation

//  MARK: CameraService Enums
extension CameraService {
    enum LivePhotoMode {
        case on
        case off
    }
    
    enum DepthDataDeliveryMode {
        case on
        case off
    }
    
    enum PortraitEffectsMatteDeliveryMode {
        case on
        case off
    }
    
    enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    enum CaptureMode: Int {
        case photo = 0
        case movie = 1
    }
}
