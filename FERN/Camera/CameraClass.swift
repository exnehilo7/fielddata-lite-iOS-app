//
//  CameraClass.swift
//  FERN
//
//  Created by Hopp, Dan on 5/17/23. Code from https://betterprogramming.pub/effortless-swiftui-camera-d7a74abde37e
//

import Foundation
import AVFoundation
import UIKit
import Photos
import Combine

public struct Photo: Identifiable, Equatable {
    
//    The ID of the captured photo
    public var id: String
    
//    Data representation of the captured photo
    public var originalData: Data
    
    public init(id: String = UUID().uuidString, originalData: Data) {
        self.id = id
        self.originalData = originalData
    }
}

extension Photo {
    public var compressedData: Data? {
        ImageResizer(targetWidth: 800).resize(data: originalData)?.jpegData(compressionQuality: 0.5)
    }
    public var thumbnailData: Data? {
        ImageResizer(targetWidth: 100).resize(data: originalData)?.jpegData(compressionQuality: 0.5)
    }
    public var thumbnailImage: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
    public var image: UIImage? {
        guard let data = compressedData else { return nil }
        return UIImage(data: data)
    }
}


public class CameraService : NSObject, ObservableObject {
    typealias PhotoCaptureSessionID = String
    
    // MARK: Observed GPS variables from the CameraView via CameraViewModel
    public var gps = "none"
    public var hdop = "0.00"
    public var longitude = "0.0000"
    public var latitude = "0.0000"
    public var altitude = "0.0000"
    
    //    MARK: Observed Properties UI must react to
    
    //    1. Tells observers whether the flash is turned ON or OFF.
    @Published public var flashMode: AVCaptureDevice.FlashMode = .off
    //    2. Tells observers whether the UI should show an alert view or not.
    @Published public var shouldShowAlertView = false
    //    3. Tells observers whether the UI should show a spinner indicating that work is going on to process the captured photo.
    @Published public var shouldShowSpinner = false
    //    4. Tells observers when a photo is about to be captured. Ideal for flashing the screen or playing an animation just before capturing the shot.
    @Published public var willCapturePhoto = false
    //    5. Self-explanatory. We start with value set to false, and once we configure the camera session successfully, we will set the value to true.
    @Published public var isCameraButtonDisabled = true
    //    6. Self-explanatory. We start with value set to false, and once we configure the camera session successfully, we will set the value to true.
    @Published public var isCameraUnavailable = true
    //    8. The photo output. The struct Photo in this case is pretty simple. Once the photo has been captured and processed, observers will receive a new value.
    @Published public var photo: Photo?
    
    // MARK: Alert properties
    public var alertError: AlertError = AlertError()
    @Published var showAlertError = false
        
    // MARK: Session Management Properties
        
    //    9. The capture session.
    public let session = AVCaptureSession()
    
    //    10. Stores whether the session is running or not.
    private var isSessionRunning = false
    
    //    11. Stores wether the session is been configured or not.
    private var isConfigured = false
    
    //    12. Stores the result of the setup process.
    private var setupResult: SessionSetupResult = .success
    
    //    13. The GDC queue to be used to execute most of the capture session's processes.
    private let sessionQueue = DispatchQueue(label: "camera session queue")
    
    //    14. The device we'll use to capture video from.
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!

    // MARK: Device Configuration Properties
    //    15. Video capture device discovery session.
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)

    // MARK: Capturing Photos Properties
    //    16. PhotoOutput. Configures and captures photos.
    private let photoOutput = AVCapturePhotoOutput()
        
    //    17 Stores delegates that will handle the photo capture process's stages.
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    // 18. To toggle the upload button on a view
    @Published public var isUploadButtonDisabled = true
    
    // MARK: KVO and Notifications Properties
    
    private var keyValueObservations = [NSKeyValueObservation]()
    
    
    public func configure() {
        /*
         Setup the capture session.
         In general, it's not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Don't perform these tasks on the main queue because
         AVCaptureSession.startRunning() is a blocking call, which can
         take a long time. Dispatch session setup to the sessionQueue, so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    
    //        MARK: Checks for user's permisions
    public func checkForPermissions() {
      
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. Suspend the session queue to delay session
             setup until the access request has completed.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access.
            // Store this result, create an alert error and tell the UI to show it.
            setupResult = .notAuthorized
            
            DispatchQueue.main.async {
                self.alertError = AlertError(title: "Camera Access", message: "SwiftCamera doesn't have access to use your camera, please update your privacy settings.", primaryButtonTitle: "Settings", secondaryButtonTitle: nil, primaryAction: {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                  options: [:], completionHandler: nil)
                    
                }, secondaryAction: nil)
                self.shouldShowAlertView = true
                self.isCameraUnavailable = true
                self.isCameraButtonDisabled = true
                self.isUploadButtonDisabled = true
            }
        }
    }
    
    //  MARK: Session Managment
        
    // Call this on the session queue.
    // - MARK: ConfigureSession
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
        session.sessionPreset = .photo
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // If the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add the photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            // May need to set to set max photo dimensions?
//            photoOutput.isHighResolutionCaptureEnabled = true // 'isHighResolutionCaptureEnabled' was deprecated in iOS 16.0: Use maxPhotoDimensions instead.
            photoOutput.maxPhotoQualityPrioritization = .quality
            
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        self.isConfigured = true
        
        self.start()
    }
    
    //  MARK: Device Configuration
    //  - MARK: ChangeCamera
    //  [Code skipped. Planned to use only back camera]
    
    //  - MARK: Focus
    // [Code skipped. May need to integrate it later?]
    
    // - MARK: Set Zoom
    public func setZoom(zoom: CGFloat){
        let factor = zoom < 1 ? 1 : zoom
        let device = self.videoDeviceInput.device
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = factor
            device.unlockForConfiguration()
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: Start capture session
    public func start() {
    //        We use our capture session queue to ensure our UI runs smoothly on the main thread.
        sessionQueue.async {
            if !self.isSessionRunning && self.isConfigured {
                switch self.setupResult {
                case .success:
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                    
                    if self.session.isRunning {
                        DispatchQueue.main.async {
                            self.isCameraButtonDisabled = false
                            self.isCameraUnavailable = false
                        }
                    }
                    
                case .configurationFailed, .notAuthorized:
                    print("Application not authorized to use camera")

                    DispatchQueue.main.async {
                        self.alertError = AlertError(title: "Camera Error", message: "Camera configuration failed. Either your device camera is not available or its missing permissions", primaryButtonTitle: "Accept", secondaryButtonTitle: nil, primaryAction: nil, secondaryAction: nil)
                        self.shouldShowAlertView = true
                        self.isCameraButtonDisabled = true
                        self.isUploadButtonDisabled = true
                        self.isCameraUnavailable = true
                    }
                }
            }
        }
    }
    
    // - MARK: Stop capture session
    public func stop(completion: (() -> ())? = nil) {
        sessionQueue.async {
            if self.isSessionRunning {
                if self.setupResult == .success {
                    self.session.stopRunning()
                    self.isSessionRunning = self.session.isRunning
                    
                    if !self.session.isRunning {
                        DispatchQueue.main.async {
                            self.isCameraButtonDisabled = true
                            self.isUploadButtonDisabled = true
                            self.isCameraUnavailable = true
                            completion?()
                        }
                    }
                }
            }
        }
    }
    
    //    MARK: Capture Photo
    // - MARK: CapturePhoto
    public func capturePhoto(
        //gps: String, hdop: String, longitude: String, latitude: String, altitude: String
        ) {
        if self.setupResult != .configurationFailed {
            self.isCameraButtonDisabled = true
            self.isUploadButtonDisabled = true
            
            sessionQueue.async {
                if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                    photoOutputConnection.videoOrientation = .portrait
                }
                var photoSettings = AVCapturePhotoSettings()
                
                // Capture HEIF photos when supported. Enable according to user settings and high-resolution photos.
                if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                }
                
                // Sets the flash option for this capture.
                if self.videoDeviceInput.device.isFlashAvailable {
                    photoSettings.flashMode = self.flashMode
                }
                
                // May need to set to set max photo dimensions?
//                photoSettings.isHighResolutionPhotoEnabled = true
                
                // Sets the preview thumbnail pixel format
                if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                    photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
                }
                
                photoSettings.photoQualityPrioritization = .quality
                
                let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings,
                                                                  // Pass GPS vars to class
                                                                  gps: self.gps,
                                                                  hdop: self.hdop,
                                                                  longitude: self.longitude,
                                                                  latitude: self.latitude,
                                                                  altitude: self.altitude,
                                                                  
                                                                  willCapturePhotoAnimation: { [weak self] in
                    // Tells the UI to flash the screen to signal that SwiftCamera took a photo.
                    DispatchQueue.main.async {
                        self?.willCapturePhoto.toggle()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.willCapturePhoto.toggle()
                    }
                    
                }, completionHandler: { [weak self] (photoCaptureProcessor) in
                    // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                    if let data = photoCaptureProcessor.photoData {
                        self?.photo = Photo(originalData: data)
                        print("passing photo")
                    } else {
                        print("No photo data")
                    }
                    
                    self?.isCameraButtonDisabled = false
                    self?.isUploadButtonDisabled = false
                    
                    self?.sessionQueue.async {
                        self?.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                    }
                }, photoProcessingHandler: { [weak self] animate in
                    // Animates a spinner while photo is processing
                    if animate {
                        self?.shouldShowSpinner = true
                    } else {
                        self?.shouldShowSpinner = false
                    }
                })
                
                // The photo output holds a weak reference to the photo capture delegate and stores it in an array to maintain a strong reference.
                self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
                self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
            }
        }
    }
}


class PhotoCaptureProcessor: NSObject {
    
    lazy var context = CIContext()
    
    private let gps: String
    private let hdop: String
    private let longitude: String
    private let latitude: String
    private let altitude: String

    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    
    private let willCapturePhotoAnimation: () -> Void
    
    private let completionHandler: (PhotoCaptureProcessor) -> Void
    
    private let photoProcessingHandler: (Bool) -> Void
    
//    private let uploadImage = UploadImage() // No uploading image for now
    
//    The actual captured photo's data
    var photoData: Data?
    
//    The maximum time lapse before telling UI to show a spinner
    private var maxPhotoProcessingTime: CMTime?
        
//    Init takes multiple closures to be called in each step of the photco capture process
    init(with requestedPhotoSettings: AVCapturePhotoSettings,
         // GPS vars from CameraService's published vars. Data is from CameraView vars.
         gps: String,
         hdop: String,
         longitude: String,
         latitude: String,
         altitude: String,
         
         willCapturePhotoAnimation: @escaping () -> Void, completionHandler: @escaping (PhotoCaptureProcessor) -> Void, photoProcessingHandler: @escaping (Bool) -> Void)
    {
        // Get them strings
        self.gps = gps
        self.hdop = hdop
        self.longitude = longitude
        self.latitude = latitude
        self.altitude = altitude
        
        self.requestedPhotoSettings = requestedPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.completionHandler = completionHandler
        self.photoProcessingHandler = photoProcessingHandler
    }
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
    
    // This extension adopts AVCapturePhotoCaptureDelegate protocol methods.
    
    // - MARK: WillBeginCapture
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        maxPhotoProcessingTime = resolvedSettings.photoProcessingTimeRange.start + resolvedSettings.photoProcessingTimeRange.duration
    }
    
    // - MARK: WillCapturePhoto
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        DispatchQueue.main.async {
            self.willCapturePhotoAnimation()
        }
        
        guard let maxPhotoProcessingTime = maxPhotoProcessingTime else {
            return
        }
        
        // Show a spinner if processing time exceeds one second.
        let oneSecond = CMTime(seconds: 2, preferredTimescale: 1)
        if maxPhotoProcessingTime > oneSecond {
            DispatchQueue.main.async {
                self.photoProcessingHandler(true)
            }
        }
    }
    
    // - MARK: DidFinishProcessingPhoto
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        DispatchQueue.main.async {
            self.photoProcessingHandler(false)
        }
        
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            photoData = photo.fileDataRepresentation()
        }
    }
    
    //        MARK: Saves capture to photo library
    // Can this call a function to upload via PHP as well?
    func saveToPhotoLibrary(_ photoData: Data, gps: String, hdop: String, longitude: String, latitude: String, altitude: String
    ) {
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
                    
                    // Try creating a custom filename
                    let fileNameUUID = UUID().uuidString
                    options.originalFilename = fileNameUUID.uppercased()
                    
                    creationRequest.addResource(with: .photo, data: photoData, options: options)

                    // Write to a .txt file
                    do {
                        // .txt file header order is uuid, gps, hdop, longitude, latitude, altitude.
                        try _ = FieldWorkGPSFile.log(uuid: fileNameUUID, gps: gps, hdop: hdop, longitude: longitude, latitude: latitude, altitude: altitude)
                    } catch {
                        // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                        print(error.localizedDescription)
                    }
                    // END write to a .txt file?
                    
                }, completionHandler: { _, error in
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                    }
                    
                    DispatchQueue.main.async {
                        self.completionHandler(self)
                    }
                }
                )
            } else {
                DispatchQueue.main.async {
                    self.completionHandler(self)
                }
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // - MARK: DidFinishCapture
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error? //,
                     //gps: String, hdop: String, longitude: String, latitude: String, altitude: String
    ) {
        if let error = error {
            print("Error capturing photo: \(error)")
            DispatchQueue.main.async {
                self.completionHandler(self)
            }
            return
        } else {
            guard let data  = photoData else {
                DispatchQueue.main.async {
                    self.completionHandler(self)
                }
                return
            }
            
            self.saveToPhotoLibrary(data, gps: gps, hdop: self.hdop, longitude: longitude, latitude: latitude, altitude: altitude)
            
            // Save to server?
//            uploadImage.myImageUploadRequest(theImage: data as UIImage)
            
        }
    }
}
