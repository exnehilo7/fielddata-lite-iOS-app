//
//  CameraView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/17/23. Code from https://betterprogramming.pub/effortless-swiftui-camera-d7a74abde37e.
//  GPS and data entry fields added by Dan Hopp.
//
//  The GPS feed defaults to the iPhone/Pad's GPS, unless the EOS device is chosen instead.
//
//  The lat, long, horizontal accuracy, and description tags are overwritten on the picture's Exif.
//
//  Only allow ASCII characters for the text fields.
//
//  Photo Group must not be null when the shutter button is pressed.

import SwiftUI
import AVFoundation

struct Article: Identifiable {
    var id: String {title}
    let title: String
    let description: String
}

struct CameraPreview: UIViewRepresentable {
    /* 1.
     We create a UIView subclass that overrides the UIView’s layer type and sets it to
     AVCaptureVideoPreviewLayer, then we create a new get-only property named videoPreviewLayer
     that returns the UIView’s layer cast as AVCaptureVideoPreviewLayer. This way we can
     use this newly created view, VideoPreviewView, in SwiftUI and set its frame and size as we
     like using the .frame() view modifiers, without the need to be passing a CGRect frame in the
     VideoPreviewView init to modify manually the video preview layer, as I’ve seen in other
     solutions in the community.
     */
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
             AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    /* 2.
     We declare a dependency on a AVCaptureSession property to be provided by CameraService,
     and we use this session to set it as the AVCaptureViewPreviewLayer’s session so the video
     preview layer can output what the camera is capturing.
     */
    let session: AVCaptureSession
    
    /* 3.
     There are two methods that theUIViewRepresentable protocol provides, makeUIView() and
     updateUIView(). As of now, we only need makeUIView() to return our view. Here we’ll init
     an instance of our just-created VideoPreviewView and add some configuration.
     */
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.cornerRadius = 0
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.connection?.videoOrientation = .portrait

        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        
    }
}

struct CameraView: View {
    
    @State private var showAlert = false
    @State private var article = Article(title: "Device Feed Error", description: "No photo was taken. Check the Bluetooth or satellite connection. If both are OK, try killing and restarting the app.")
    
    // Camera
    @StateObject var model = CameraService() // Try skipping middleman CameraViewModel() to get the GPS feed-to-variables to work
    @State var currentZoomFactor: CGFloat = 1.0

    // GPS
    // Arrow Gold
    @ObservedObject var nmea:NMEA = NMEA()
    
    // Default iOS
    @ObservedObject var clLocationHelper = LocationHelper()
    var clLat:String {
        return "\(clLocationHelper.lastLocation?.coordinate.latitude ?? 0.0000)"
    }
    var clLong:String {
        return "\(clLocationHelper.lastLocation?.coordinate.longitude ?? 0.0000)"
    }
    var clHorzAccuracy:String {
        return "\(clLocationHelper.lastLocation?.horizontalAccuracy ?? 0.00)"
    }
    var clVertAccuracy:String {
        return "\(clLocationHelper.lastLocation?.verticalAccuracy ?? 0.00)"
    }
    var clAltitude:String {
        return "\(clLocationHelper.lastLocation?.altitude ?? 0.0000)"
    }
    
    // Select GPS and display toggles
    @State var gpsModeIsSelected = false
    @State var showArrowGold = false

    // User info for Exif Description tag
    @State private var textPhotoGroup = "A Photo Group (A dropdown? Preselected from a previous screen?)"
    @State private var textOrganismName = ""
    @State private var textGenotype = ""
    @State private var textNotes = ""
    
    // For the camera's current image?
//    @State private var image = UIImage()
    
    // Upload the photo  // No need to upload the photo for now
//    @ObservedObject var uploadPhoto = UploadPhoto()
//    @State private var isShowUploadButton = false
    
    // Get a message from Upload Photo
//    var responseMessage: some View {
//        VStack {
//            Text("PHP Response: \(uploadPhoto.responseString ?? "None")")
//        }.font(.system(size: 20)).foregroundColor(.white)
//            .padding()
//    }
    
    var captureButton: some View {
        Button(action: {
            if showArrowGold {
                // Pass GPS data
                model.gps = "ArrowGold"
                model.hdop = nmea.accuracy ?? "0.00"
                model.longitude = nmea.longitude ?? "0.0000"
                model.latitude = nmea.latitude ?? "0.0000"
                model.altitude = nmea.altitude ?? "0.00"
                
                // If there's no feed, don't capture the photo
                if nmea.hasNMEAStreamStopped ||
                    (model.hdop == "0.00" || model.longitude == "0.0000" ||
                     model.latitude == "0.0000" || model.altitude == "0.00")
                {
                    model.photo = nil
                    showAlert = true
                } else {
                    model.capturePhoto()
                }
            } else {
                model.gps = "iOS"
                model.hdop = clHorzAccuracy
                model.longitude = clLong
                model.latitude = clLat
                model.altitude = clAltitude
                model.capturePhoto()
            }
            
//            isShowUploadButton = true // try to toggle show upload button
//            uploadPhoto.setResponseMsgToBlank() // Clear out response message
        }, label: {
            Circle()
                .foregroundColor(.white)
                .frame(width: 80, height: 80, alignment: .center)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.8), lineWidth: 2)
                        .frame(width: 65, height: 65, alignment: .center)
                )
        }).alert(article.title, isPresented: $showAlert, presenting: article) {article in Button("OK"){showAlert = false}} message: {article in Text(article.description)}
    }
    
    var capturedPhotoThumbnail: some View {
        Group {
            if model.photo != nil {
                VStack {
                    // Original code had a thumbnail pop up
                    Image(uiImage: (model.photo?.image!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .animation(.spring(), value: true)
                    //                // Try button popup
                    //                    .onAppear(perform: {isShowUploadButton = true})
                    Text("Pic taken!").foregroundColor(.white)
                }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 60, height: 60, alignment: .center)
                    .foregroundColor(.black)
            }
        }
    }
    
//    var uploadButton: some View {
//        Group {
//            if model.photo != nil  {
//                Button(action: {
//                    var lat: String!
//                    var long: String!
//                    if showArrowGold {
//                        lat = nmea.latitude ?? "0.0000"
//                        long = nmea.longitude ?? "0.0000"
//                    }
//                    else {
//                        lat = clLat
//                        long = clLong
//                    }
//
//                    // uploadPhoto.myImageUploadRequestTEST()
//                    uploadPhoto.myPhotoUploadRequest(thePhoto: model.photo, lat: lat, long: long)
//
//                    // Hide upload button
//                    isShowUploadButton = false // try to toggle show upload button
//                })
//                {
//                    HStack {
//                        Image(systemName: "arrow.up")
//                            .font(.system(size: 20))
//
//                        Text("Upload Image")
//                            .font(.headline)
//                    }
//                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
//                    .background(Color.orange)
//                    .foregroundColor(.white)
//                    .cornerRadius(20)
//                    .padding(.horizontal)
//                }
//            } else {
//                RoundedRectangle(cornerRadius: 20)
//                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
//                    .foregroundColor(.black)
//            }
//        }
//    }
    
//    var flipCameraButton: some View {
//        Button(action: {
//            model.flipCamera()
//        }, label: {
//            Circle()
//                .foregroundColor(Color.gray.opacity(0.2))
//                .frame(width: 45, height: 45, alignment: .center)
//                .overlay(
//                    Image(systemName: "camera.rotate.fill")
//                        .foregroundColor(.white))
//        })
//    }
    
    // Arrow Gold
    var arrowGpsData: some View {
        VStack {
            
            Label("EOS Arrow Gold", systemImage: "antenna.radiowaves.left.and.right").underline()
//            Text("Protocol: ") + Text(nmea.protocolText as String)
            Text("Latitude: ") + Text(nmea.latitude ?? "0.0000")
            Text("Longitude: ") + Text(nmea.longitude ?? "0.0000")
            Text("Altitude: ") + Text(nmea.altitude ?? "0.00")
            Text("Horizontal Accuracy: ") + Text(nmea.accuracy ?? "0.00")
            Text("GPS Used: ") + Text(nmea.gpsUsed ?? "No GPS")
        }.font(.system(size: 20)).foregroundColor(.white)
    }
    

    // iOS Core Location
    var coreLocationGpsData: some View {
        VStack {
            
            Label("Standard GPS (May need time to start feed)",  systemImage: "location.fill").underline()
            Text("Latitude: ") + Text("\(clLat)")
            Text("Longitude: ") + Text("\(clLong)")
            Text("Altitude (m): ") + Text("\(clAltitude)")
            Text("Horizontal Accuracy (m): ") + Text("\(clHorzAccuracy)")
            Text("Vertical Accuracy (m): ") + Text("\(clVertAccuracy)")
        }.font(.system(size: 20)).foregroundColor(.white)
            .padding()
    }
    
    var selectGpsMode: some View {
        HStack {
            HStack{
                Button{
                    // (22-AUG-2023: Need to initiate the camera class(?) and CoreLocation on button press, not on view load?)
                    gpsModeIsSelected = true
                    createTxtFileForTheDay()
                    UIApplication.shared.isIdleTimerDisabled = true
                } label: {
                    Label("Use Standard GPS", systemImage: "location.fill")
                }.buttonStyle(.borderedProminent)
            }.padding(.leading, 20)
            Spacer()
            HStack{
                Button{
                    showArrowGold = true
                    clLocationHelper.stopUpdatingDefaultCoreLocation() // basic core off
                    nmea.viewDidLoad()
                    gpsModeIsSelected = true
                    createTxtFileForTheDay()
                    // To prevent the device feed from being interruped, disable autosleep
                    UIApplication.shared.isIdleTimerDisabled = true
                } label: {
                    Label("Use Arrow Gold Device", systemImage: "antenna.radiowaves.left.and.right").foregroundColor(.black)
                }.buttonStyle(.borderedProminent).tint(.yellow)
            }.padding(.trailing, 20)
        }
    }
    
    private func createTxtFileForTheDay() {
        do{
            // create new txt file for the day for GPS data. Note that for now, within the static function, the user's name is hard coded to the filename
            _ = try FieldWorkGPSFile.log(uuid: "", gps: "", hdop: "", longitude: "", latitude: "", altitude: "")
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            print(error.localizedDescription)
        }
    }
    
    var userData: some View {
        VStack {
            HStack {
                Text("Photo Group: ").foregroundColor(.white)
                TextField("", text: $textPhotoGroup
                ).textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("Organism Name: ").foregroundColor(.white)
                TextField("", text: $textOrganismName
                ).textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("Genotype: ").foregroundColor(.white)
                TextField("", text: $textGenotype
                ).textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("Notes: ").foregroundColor(.white)
                TextField("", text: $textNotes
                ).textFieldStyle(.roundedBorder)
            }
        }
    }
    
    var body: some View {
        GeometryReader { reader in
            ZStack {
                Color.black.ignoresSafeArea(.all)
                
                VStack {
//                    Button(action: {
//                        model.switchFlash()
//                    }, label: {
//                        Image(systemName: model.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
//                            .font(.system(size: 20, weight: .medium, design: .default))
//                    })
//                    .accentColor(model.isFlashOn ? .yellow : .white)
                    
                    CameraPreview(session: model.session)
                        .gesture(
                            DragGesture().onChanged({ (val) in
                                //  Only accept vertical drag
                                if abs(val.translation.height) > abs(val.translation.width) {
                                    //  Get the percentage of vertical screen space covered by drag
                                    let percentage: CGFloat = -(val.translation.height / reader.size.height)
                                    //  Calculate new zoom factor
                                    let calc = currentZoomFactor + percentage
                                    //  Limit zoom factor to a maximum of 5x and a minimum of 1x
                                    let zoomFactor: CGFloat = min(max(calc, 1), 5)
                                    //  Store the newly calculated zoom factor
                                    currentZoomFactor = zoomFactor
                                    //  Sets the zoom factor to the capture device session
//                                    model.zoom(with: zoomFactor) // Commented out to skip middleman CameraViewModel
                                    model.setZoom( zoom: zoomFactor)
                                }
                            })
                        )
                        .onAppear {
                            model.configure()
                        }
                        .alert(isPresented: $model.showAlertError, content: { // When removing the middleman CameraViewModel(), showAlertError was added to the CameraService class. Unknown if its Bool will toggle.
                            Alert(title: Text(model.alertError.title), message: Text(model.alertError.message), dismissButton: .default(Text(model.alertError.primaryButtonTitle), action: {
                                model.alertError.primaryAction?()
                            }))
                        })
                        .overlay(
                            Group {
                                if model.willCapturePhoto {
                                    Color.black
                                }
                            }
                        )
                        .animation(.easeInOut, value: true)
                    
//                    Spacer()
//                    
//                    VStack {
                        if gpsModeIsSelected {
                            if showArrowGold {
                                arrowGpsData
                            }
                            else {
                                coreLocationGpsData
                            }
                            
                            // Disable photo upload response message for now
//                            Spacer()
//                            responseMessage
                            
                            Spacer()
                            
                            // Disable user data for now
//                            userData
//                            Spacer()
                            
                            HStack {
                                // Disable photo thumbnail popup?
//                                NavigationLink(destination: Text("Detail photo")) {
                                capturedPhotoThumbnail
//                                }
                                
                                Spacer()
                                captureButton
                                Spacer()
                                
        //                        flipCameraButton
                            }//.padding(.horizontal, 20)
                            
                            // Disable photo upload for now
//                            Spacer()
//                            if isShowUploadButton { // try to toggle show upload button
//                                uploadButton
//                            }
                        }
                        else {
                            selectGpsMode
                        }
//                    }.animation(.easeInOut, value: true)  // Vstack ender
                    
                }//.sheet(isPresented: $gpsModeIsSelected) {
//                    ImagePicker(sourceType: .camera, selectedImage: self.$image) // May need a 3rd param for button-show toggle
//                }
            }//.preferredColorScheme(.dark) // Make the status bar show on black background
        }
    }
}

//struct CameraView_Previews: PreviewProvider {
//    static var previews: some View {
//        CameraView()
//    }
//}
