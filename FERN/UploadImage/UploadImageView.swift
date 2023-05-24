//
//  UploadImageView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/23/23. Image picker help from https://www.appcoda.com/swiftui-camera-photo-library/
//

import SwiftUI
import UIKit

struct UploadImageView: View {
    
    @State private var isShowCamera = false
    @State private var isResponseReceived = false
    @State private var isShowUploadButton = false
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
                    self.isShowCamera = true
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
                if isShowUploadButton {
                    Button(action: {
                        //                    uploadImage.myImageUploadRequestTEST()
                        uploadImage.myImageUploadRequest(theImage: self.image)

                        // NEED TO TELL IF UPLOAD WAS SUCESSFUL OR NOT
                        // Present response to user
                        // isResponseReceived = uploadImage.isResponseReceived

                        // Clear displayed image
                        self.image = UIImage()
                        
                        // Hide upload button
                        isShowUploadButton = false
                    })
                    {
                        HStack {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20))
                            
                            Text("Upload Image")
                                .font(.headline)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }.alert(uploadImage.responseString as? String ?? "No response", isPresented: $isResponseReceived) {
                        Button("OK", role: .cancel) { isResponseReceived = false }
                    }
                }
            }

        }.sheet(isPresented: $isShowCamera) {
            ImagePicker(sourceType: .camera, selectedImage: self.$image, imageIsSelected: self.$isShowUploadButton)
        }.animation(.easeInOut, value: true)
        
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
