//
//  UploadImageView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/23/23. Image picker help from https://www.appcoda.com/swiftui-camera-photo-library/
//

import SwiftUI
import UIKit

struct UploadImageView: View {
    
    @State private var isShowPhotoLibrary = false
    @State private var image = UIImage()
    
    let uploadImage = UploadImage()
    let myPickerController = UIImagePickerController()
    
    var body: some View {
        VStack {
         
            Image(uiImage: self.image)
                .resizable()
                .scaledToFit()
//                .frame(minWidth: 0, maxWidth: .infinity)  // Deprecated
//                .edgesIgnoringSafeArea(.all)              // Deprecated
 
            HStack {
                Button(action: {
                    self.isShowPhotoLibrary = true
                }) {
                    HStack {
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                        
                        Text("Photo")
                            .font(.headline)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
                Button(action: {
//                    uploadImage.myImageUploadRequestTEST()
                    uploadImage.myImageUploadRequest(theImage: self.image)
                }) {
                    HStack {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 20))
                        
                        Text("Upload Image")
                            .font(.headline)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
//                Button("Upload Image") {
//    //                uploadImage.myImageUploadRequest(theImage: self.image)
//                    uploadImage.myImageUploadRequestTEST()
//                }
            }

        }.sheet(isPresented: $isShowPhotoLibrary) {
            ImagePicker(sourceType: .camera, selectedImage: self.$image)
        }
        
//        HStack {
//            Button("Select Photos") {
////                myPickerController.delegate = self
////                myPickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
////
////                self.presentViewController(myPickerController, animated: true, completion: nil)
//            }.buttonStyle(.borderedProminent)
//            Button("Upload Images") {
//                uploadImage.myImageUploadRequest()
//            }
//        }
    }
    
}

//struct UploadImageView_Previews: PreviewProvider {
//    static var previews: some View {
//        UploadImageView()
//    }
//}
