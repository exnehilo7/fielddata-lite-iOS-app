//
//  CameraView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/17/23. Code from https://betterprogramming.pub/effortless-swiftui-camera-d7a74abde37e
//

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
    @StateObject var model = CameraViewModel()
    
    @State var currentZoomFactor: CGFloat = 1.0
    
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
                    
                    
                    HStack {
                        capturedPhotoThumbnail
                        
                        Spacer()
                        
                        captureButton
                        
                        Spacer()
                        
//                        flipCameraButton
                        
                    }
                    .padding(.horizontal, 20)
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
