//
//  CameraViewModel.swift
//  FERN
//
//  Created by Hopp, Dan on 5/17/23. Code from https://betterprogramming.pub/effortless-swiftui-camera-d7a74abde37e
//
// 18-JUL-2023: Model skipped to get class's GPS variables working

/*
 Before entering into UI design with SwiftUI, we need a critical component to make this app composable
 and reusable, that is, something to link the UI with our CameraService.In this tutorial, we’ll be using
 MVVM as our design pattern of choice, so each view needs a model. For our CameraView we’ll create a
 CameraViewModel. This object will be in charge of using the CameraService, configuring it and calling all
 its methods on behalf of the UI, as well as doing any needed data formatting.
 */


import Foundation
import Combine
import AVFoundation

final class CameraViewModel: ObservableObject {
    private let service = CameraService()
    
    @Published var photo: Photo!
    
    @Published var showAlertError = false
    
    @Published var isFlashOn = false
    
    @Published var willCapturePhoto = false
    
    @Published var isUploadButtonDisabled = true
    
    // GPS info
//    @Published var gps = "middleman"
//    @Published var hdop = ""
//    @Published var longitude = ""
//    @Published var latitude = ""
//    @Published var altitude = ""
    
    var alertError: AlertError!
    
    var session: AVCaptureSession
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        self.session = service.session
        
        service.$photo.sink { [weak self] (photo) in
            guard let pic = photo else { return }
            self?.photo = pic
        }
        .store(in: &self.subscriptions)
        
        service.$shouldShowAlertView.sink { [weak self] (val) in
            self?.alertError = self?.service.alertError
            self?.showAlertError = val
        }
        .store(in: &self.subscriptions)
        
        service.$flashMode.sink { [weak self] (mode) in
            self?.isFlashOn = mode == .on
        }
        .store(in: &self.subscriptions)
        
        service.$willCapturePhoto.sink { [weak self] (val) in
            self?.willCapturePhoto = val
        }
        .store(in: &self.subscriptions)
        
        // For uploads
        service.$isUploadButtonDisabled.sink { [weak self] (val) in
            self?.isUploadButtonDisabled = val
        }
        .store(in: &self.subscriptions)
        
//        // GPS vars
//        service.$gps.sink { [weak self] (val) in
//            self?.gps = val
//        }
//        .store(in: &self.subscriptions)
//
//        service.$hdop.sink { [weak self] (val) in
//            self?.hdop = val
//        }
//        .store(in: &self.subscriptions)
//
//        service.$longitude.sink { [weak self] (val) in
//            self?.longitude = val
//        }
//        .store(in: &self.subscriptions)
//
//        service.$latitude.sink { [weak self] (val) in
//            self?.latitude = val
//        }
//        .store(in: &self.subscriptions)
//
//        service.$altitude.sink { [weak self] (val) in
//            self?.altitude = val
//        }
//        .store(in: &self.subscriptions)
        
    }
    
    func configure() {
        service.checkForPermissions()
        service.configure()
    }
    
    func capturePhoto(
        //gps: String, hdop: String, longitude: String, latitude: String, altitude: String
        ) {
        service.capturePhoto(
            //gps: gps, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude
        )
    }
    
    //    func flipCamera() {
    //        service.changeCamera()
    //    }
    
    func zoom(with factor: CGFloat) {
        service.setZoom(zoom: factor)
    }
    
    func switchFlash() {
        service.flashMode = service.flashMode == .on ? .off : .on
    }
    
}

// Attempt to Include alerts from UploadPhotoClass
//final class UploadPhotoModel: ObservableObject {
//    
//    var session: AVCaptureSession
//    
//    private var uploadPhotoSubs = Set<AnyCancellable>()
//        
//    private let uploadPhotoService = UploadPhoto()
//    @Published var showPhotoUploadAlert = false
//    var uploadPhotoAlert: AlertError!
//    
//    init() {
//
//        self.session = uploadPhotoService
//        
//        uploadPhotoService.$shouldShowPhotoUploadAlert.sink { [weak self] (val) in
//            self?.uploadPhotoAlert = self?.uploadPhotoService.uploadPhotoAlert
//            self?.showPhotoUploadAlert = val
//        }
//        .store(in: &self.uploadPhotoSubs)
//    }
//}


