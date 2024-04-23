//
//  UploadPhotoClass.swift
//  FERN
//
//  Created by Hopp, Dan on 5/24/23. Code from https://swiftdeveloperblog.com/image-upload-example/. Adjusted for
//  Swift 5.8. Tweaked to use Photo instead of Image
//

import Foundation
import UIKit


class UploadPhoto: NSObject, UINavigationControllerDelegate, ObservableObject {
    
//    var myActivityIndicator: UIActivityIndicatorView!
//    var myPhotoView: UIPhotoView!
    
//    var uploadResponseMessage = UIAlertController()
    
    @Published var responseString: NSString?
    var isResponseReceived: Bool!
    
    private var fileNameCounter = 0
    
    // Can an alert model be used?
//    public var uploadPhotoAlert: AlertError = AlertError()
//    @Published public var shouldShowPhotoUploadAlert = false
    
    func myPhotoUploadRequestTEST(){
        print ("Upload the Photo!")
    }
    
    func myPhotoUploadRequest(thePhoto: Photo, lat: String, long: String, uploadScriptURL: String)
        {
      
            let myUrl = NSURL(string: uploadScriptURL)
            
            let request = NSMutableURLRequest(url:myUrl! as URL)
            request.httpMethod = "POST"
            
            let param = [
                "firstName"     : "FERN",
                "lastName"      : "Demo",
                "userId"        : "0",
                "lat"           : lat,
                "long"          : long
            ]
            
            let boundary = generateBoundaryString()
            
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
     
            // Need to get image from SwiftUI's view/ImagePicker class? Pass a PhotoData var?
//            let imageData = myImageView.image!.jpegData(compressionQuality: 1)
            let photoData = thePhoto.originalData  // or .image?
            
//            if(thePhoto==nil)  { return }
            
            request.httpBody = createBodyWithParameters(parameters: param, filePathKey: "file", photoDataKey: photoData as NSData, boundary: boundary)
            
            
//            myActivityIndicator.startAnimating();
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if error != nil {
                    print("error=\(String(describing: error))")
//                    self.shouldShowPhotoUploadAlert = false
                    return
                }
                
                // You can print out response object
                print("******* response = \(String(describing: response))")
                
                // Print out reponse body
                DispatchQueue.main.async { [self] in
                    self.responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    print("****** response data = \(self.responseString!)")
                    self.isResponseReceived = true
                }
                
                // Display response to user
                // Can an alert model be used?
//                self.uploadPhotoAlert = AlertError(title: "PHP Response", message: "\(self.responseString!)", primaryButtonTitle: "OK", secondaryButtonTitle: nil, primaryAction: nil, secondaryAction: nil)
//                self.shouldShowPhotoUploadAlert = true
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary
                    
                    print(json as Any)
                    
                    // dispatch_async(dispatch_get_main_queue() is Obj-C
//                    dispatch_async(dispatch_get_main_queue(),{
//                        self.myActivityIndicator.stopAnimating()
//                        self.myImageView.image = nil;
//                    })
                    
//                    DispatchQueue.main.async {
//                        // May need to interact with ImagePicker class
//                        self.myImageView.image = nil
//                    }
                    
                }catch
                {
                    print(error)
//                    self.shouldShowPhotoUploadAlert = false
                }
                
            }
            
            task.resume()
    }
    
    
    func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, photoDataKey: NSData, boundary: String) -> Data {
//        let body = NSMutableData() // A dynamic byte buffer that bridges to Data; use NSMutableData when you need reference semantics or other Foundation-specific behavior. (Now recomended to use the new Data struct?)
        
        var body = Data()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.append(Data("--\(boundary)\r\n".utf8))
                body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8))
                body.append(Data("\(value)\r\n".utf8))
            }
        }
       
        var filename = String(fileNameCounter)
        filename.append("_")
//                filename.append(UUID().uuidString)
        filename.append("CBI2-Demo-Photo")
        filename.append(".jpg")
        let mimetype = "image/jpg"  // exiftool says type is heic?

        fileNameCounter += 1
        
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimetype)\r\n\r\n".utf8))
        body.append(photoDataKey as Data)
        body.append(Data("\r\n".utf8))
        
    
        
        body.append(Data("--\(boundary)--\r\n".utf8))
        
        return body
    }
    
    
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
 
    func setResponseMsgToBlank() {
        DispatchQueue.main.async { [self] in
            self.responseString = "None"
        }
    }
 
}

// Not needed for current version of Swift
//extension NSMutableData {
//
//    func appendString(string: String) {
//        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
//        appendData(data!)
//    }
//}
