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
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .edgesIgnoringSafeArea(.all)
 
            HStack {
                Button(action: {
                    self.isShowPhotoLibrary = true
                }) {
                    HStack {
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                        
                        Text("Photos")
                            .font(.headline)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
            }
            Button("Upload Image") {
//                uploadImage.myImageUploadRequest(theImage: self.image)
                uploadImage.myImageUploadRequestTEST()
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
