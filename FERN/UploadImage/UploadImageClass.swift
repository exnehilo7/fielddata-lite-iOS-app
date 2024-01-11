//
//  UploadImageClass.swift
//  FERN
//
//  Created by Hopp, Dan on 5/23/23. Code from https://swiftdeveloperblog.com/image-upload-example/. Adjusted for
//  Swift 5.8.
//
//  11-JAN-2024 - Set upload to:
//  Upload a trip's folders and files. Create folders on server when req'd.

import Foundation
import UIKit


class UploadImage: NSObject, UINavigationControllerDelegate, ObservableObject {
    
//    var myActivityIndicator: UIActivityIndicatorView!
//    var myImageView: UIImageView!
    
//    var uploadResponseMessage = UIAlertController()
    
    @Published var responseString: NSString?
    var isResponseReceived: Bool!
    
    private var fileNameCounter = 0
    
    func myImageUploadRequestTEST(tripName: String){
        
        let fm = FileManager.default
        
        // Get app's root dir
        var rootDir: URL? {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            return documentsDirectory
        }
    
        var path: URL
        var getFilePath: URL
        var uploadFilePath: String
        
        // Get device ID and make path
        if let deviceUuid = UIDevice.current.identifierForVendor?.uuidString
        {
            uploadFilePath = "\(deviceUuid)/trips/\(tripName)"
            path = (rootDir?.appendingPathComponent(uploadFilePath))!
        } else {
            uploadFilePath = "no_device_uuid/trips/\(tripName)"
            path = (rootDir?.appendingPathComponent(uploadFilePath))!
        }
        
        // loop through files in folder and print the path
        do {
            let items = try fm.contentsOfDirectory(atPath: path.path)

            for item in items {
                // Just the filename
                print("\(item)")
                
                // path to save the file:
                print("\(uploadFilePath)/\(item)")
                
                // path to get the file:
                getFilePath = path.appendingPathComponent(item)
                print(getFilePath)
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print("Directory loop error")
        }
    }
    
    func myFileUploadRequest(tripName: String)
        {
      
            // Set endpoint
            let myUrl = NSURL(string: "http://103.72.77.233/ORNL/fielddata-lite/php/upload.php") // http://covid-samples01.ornl.gov/upload.php
            
            let request = NSMutableURLRequest(url:myUrl! as URL)
            request.httpMethod = "POST"
            
            let param = [
                "firstName"     : "FERN",
                "lastName"      : "Demo",
                "userId"        : "0"
            ]
            
            let boundary = generateBoundaryString()
            
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // FILE LOOPS
            let fm = FileManager.default
            
            // Get app's root dir
            var rootDir: URL? {
                guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
                return documentsDirectory
            }
        
            var path: URL
            var getFile: URL
            var uploadFilePath: String
            
            // Get device ID and make path
            if let deviceUuid = UIDevice.current.identifierForVendor?.uuidString
            {
                uploadFilePath = "\(deviceUuid)/trips/\(tripName)"
                path = (rootDir?.appendingPathComponent(uploadFilePath))!
            } else {
                uploadFilePath = "no_device_uuid/trips/\(tripName)"
                path = (rootDir?.appendingPathComponent(uploadFilePath))!
            }
            
            // loop through files in folder and print the path
            do {
                let items = try fm.contentsOfDirectory(atPath: path.path)

                for item in items {
                    // Just the filename
                    print("\(item)")
                    
                    // path to save the file:
                    print("\(uploadFilePath)/\(item)")
                    
                    // path to get the file:
                    getFile = path.appendingPathComponent(item)
                    print(getFile)
                }
            } catch {
                // failed to read directory – bad permissions, perhaps?
                print("Directory loop error")
            }
            
            
            
            
            
            
            
            
            // Need to get image from SwiftUI's view/ImagePicker class? Pass a PhotoData var?
//            let imageData = myImageView.image!.jpegData(compressionQuality: 1)
//            let imageData = theImage.jpegData(compressionQuality: 1)
//            
//            if(imageData==nil)  { return }
            
//            request.httpBody = createBodyWithParameters(parameters: param, filePathKey: "file", imageDataKey: imageData! as NSData, boundary: boundary)
            
            
//            myActivityIndicator.startAnimating();
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if error != nil {
                    print("error=\(String(describing: error))")
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
                
//                // Display response to user
//                self.uploadResponseMessage = UIAlertController(title: "Response", message: responseString! as String, preferredStyle: .alert)
//                // Create OK button with action handler
//                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
//                    print("Response Ok button tapped")
//                 })
//                //Add OK button to a dialog message
//                self.uploadResponseMessage.addAction(ok)
                
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
                }
                
            }
            
            task.resume()
    }
    
    
    func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, imageDataKey: NSData, boundary: String) -> Data {
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
//      filename.append(UUID().uuidString)
        filename.append("CBI2-Demo-Image")
        filename.append(".jpg")
        
        // Seperate pics and text
//        if item.hasSuffix(".heic") {
//            print("Found heic! \(item)")
//        }
//        else if item.hasSuffix(".txt") {
//            print("Found text! \(item)")
//        }
        let mimetype = "image/jpg"
        
        fileNameCounter += 1
                
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimetype)\r\n\r\n".utf8))
        body.append(imageDataKey as Data)
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

func myImageUploadRequest(theImage: UIImage, lat: String, long: String)
{
    // nothing!
}

// Not needed for current version of Swift
//extension NSMutableData {
//
//    func appendString(string: String) {
//        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
//        appendData(data!)
//    }
//}
