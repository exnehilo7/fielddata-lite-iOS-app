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
    
    // Camera
    @StateObject var model = CameraViewModel()
    @State var currentZoomFactor: CGFloat = 1.0

    // GPS
    @ObservedObject var nmea:NMEA = NMEA()
    @ObservedObject var clLocationHelper = LocationHelper()
    var clLat:String {
        return "Latitude: \(clLocationHelper.lastLocation?.coordinate.latitude ?? 0.0000)"
    }
    var clLong:String {
        return "Longitude: \(clLocationHelper.lastLocation?.coordinate.longitude ?? 0.0000)"
    }
    var clHorzAccuracy:String {
        return "Horizontal Accuracy (m): \(clLocationHelper.lastLocation?.horizontalAccuracy ?? 0.00)"
    }
    var clVertAccuracy:String {
        return "Vertical Accuracy (m): \(clLocationHelper.lastLocation?.verticalAccuracy ?? 0.00)"
    }
    var clAltitude:String {
        return "Altitude (m): \(clLocationHelper.lastLocation?.altitude ?? 0.0000)"
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
    @State private var image = UIImage()
    
    var captureButton: some View {
        Button(action: {
            model.capturePhoto()
        }, label: {
            Circle()
                .foregroundColor(.white)
                .frame(width: 80, height: 80, alignment: .center)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.8), lineWidth: 2)
                        .frame(width: 65, height: 65, alignment: .center)
                )
        })
    }
    
    var capturedPhotoThumbnail: some View {
        Group {
            if model.photo != nil {
                Image(uiImage: (model.photo?.image!)!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .animation(.spring(), value: true)
                
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 60, height: 60, alignment: .center)
                    .foregroundColor(.black)
            }
        }
    }
    
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
    
    var arrowGpsData: some View {
        VStack {
            // Arrow Gold
            Label("EOS Arrow Gold", systemImage: "antenna.radiowaves.left.and.right").underline()
//            Text("Protocol: ") + Text(nmea.protocolText as String)
            Text("Latitude: ") + Text(nmea.latitude ?? "0.0000")
            Text("Longitude: ") + Text(nmea.longitude ?? "0.0000")
            Text("Altitude: ") + Text(nmea.altitude ?? "0.00")
            Text("Horizontal Accuracy: ") + Text(nmea.accuracy ?? "0.00")
            Text("GPS Used: ") + Text(nmea.gpsUsed ?? "No GPS")
        }.font(.system(size: 20)).foregroundColor(.white)
    }
    
    var coreLocationGpsData: some View {
        VStack {
            // Default Core Location
            Label("Standard GPS",  systemImage: "location.fill").underline()
            Text("\(clLat)")
            Text("\(clLong)")
            Text("\(clAltitude)")
            Text("\(clHorzAccuracy)")
            Text("\(clVertAccuracy)")
        }.font(.system(size: 20)).foregroundColor(.white)
            .padding()
    }
    
    var selectGpsMode: some View {
        HStack {
            Button{
                gpsModeIsSelected = true
            } label: {
                Label("Use Standard GPS", systemImage: "location.fill")
            }.buttonStyle(.borderedProminent)
            Button{
                showArrowGold = true
                clLocationHelper.stopUpdatingDefaultCoreLocation() // basic core off
                nmea.viewDidLoad()
                gpsModeIsSelected = true
            } label: {
                Label("Use Arrow Gold Device", systemImage: "antenna.radiowaves.left.and.right")
            }.buttonStyle(.borderedProminent)
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
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    Button(action: {
                        model.switchFlash()
                    }, label: {
                        Image(systemName: model.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 20, weight: .medium, design: .default))
                    })
                    .accentColor(model.isFlashOn ? .yellow : .white)
                    
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
                                    model.zoom(with: zoomFactor)
                                }
                            })
                        )
                        .onAppear {
                            model.configure()
                        }
                        .alert(isPresented: $model.showAlertError, content: {
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
                    
                    Spacer()
                    
                    VStack {
                        if gpsModeIsSelected {
                            if showArrowGold {
                                arrowGpsData
                            }
                            else {
                                coreLocationGpsData
                            }
                            
                            Spacer()
                            
                            userData
                            Spacer()
                            
                            HStack {
                                NavigationLink(destination: Text("Detail photo")) {
                                    capturedPhotoThumbnail
                                }
                                
                                Spacer()
                                
                                captureButton
                                
                                Spacer()
                                
        //                        flipCameraButton
                            }//.padding(.horizontal, 20)
                        }
                        else {
                            selectGpsMode
                        }
                    }.animation(.easeInOut, value: true)
                    
                }.sheet(isPresented: $gpsModeIsSelected) {
                    ImagePicker(sourceType: .camera, selectedImage: self.$image)
                }
            }
        }
    }
}

//struct CameraView_Previews: PreviewProvider {
//    static var previews: some View {
//        CameraView()
//    }
//}
