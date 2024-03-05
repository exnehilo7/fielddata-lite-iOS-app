//
//  UploadImageClass.swift
//  FERN
//
//  Created by Hopp, Dan on 5/23/23. Code from https://swiftdeveloperblog.com/image-upload-example/. Adjusted for
//  Swift 5.8.
//
//  11-JAN-2024 - Set upload to: Upload a trip's folders and files.
//  19-JAN-2024 - Switch to SwiftData

import Foundation
import UIKit
import SwiftData


class UploadImage: NSObject, UINavigationControllerDelegate, ObservableObject {
    
//    var myActivityIndicator: UIActivityIndicatorView!
//    var myImageView: UIImageView!
    
//    var uploadResponseMessage = UIAlertController()
    
    
    @Published var responseString: NSString?
    var isResponseReceived: Bool!
    
    private var fileNameCounter = 0
    
    // For progress bar
//    @Published var uploadProg = 0
    @Published var totalUploaded = 0
    @Published var totalFiles = 0
    
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
    
//    func myFileUploadRequest(tripName: String, uploadScriptURL: String, trip: Trip, modelContext: "type" )
    func myFileUploadRequest(tripName: String, uploadScriptURL: String, trip: SDTrip)
        {
            DispatchQueue.global().async {
                
                // Set endpoint
                let myUrl = NSURL(string: uploadScriptURL)
                
                let request = NSMutableURLRequest(url:myUrl! as URL)
                request.httpMethod = "POST"
                
                let boundary = self.generateBoundaryString()
                
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                // FILE LOOP
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
                
                // Get a list of all trip files: loop through filenames and insert into Trip files array. Set isUploaded to false
                do {
                    let items = try fm.contentsOfDirectory(atPath: path.path)
                    
                    // Clear trips
                    trip.files?.removeAll()
                    
                    // Populate trips
                    for item in items {
                        // Just the filename
                        print("\(item)")
                        trip.files?.append(TripFile(fileName: item, isUploaded: false))
                    }
                } catch {
                    // failed to read directory – bad permissions, perhaps?
                    print("Directory loop error")
                }
                
                
                // Get file items
                let items = trip.files
                
                // get total number of files
                DispatchQueue.main.async {
                    self.totalFiles = items?.count ?? 0
                }
                
                // Reset counters
                DispatchQueue.main.async {
                    self.totalUploaded = 0
                }
                //            uploadProg = 0
                
                // get total of uploaded
                for item in items ?? [] {
                    if item.isUploaded {
                        print("\(item.fileName) has already been uploaded!")
                        DispatchQueue.main.async {
                            self.totalUploaded += 1
                        }
                    }
                }
                
                let param = [
                    "firstName"     : "FERN",
                    "lastName"      : "Demo",
                    "userId"        : "0",
                    "fileSavePath"  : "\(uploadFilePath)"
                ]
                
                // loop through files in trip array
                for item in items ?? [] {
                    
                    // if isUploaded = false
                    if (!item.isUploaded) {
                        
                        // path to save the file:
                        let pathAndFile = "\(uploadFilePath)/\(item.fileName)"
                        
                        // path to get the file:
                        getFile = path.appendingPathComponent(item.fileName)
                        
                        request.httpBody = self.createBodyWithParameters(parameters: param, filePathKey: "file", fileData: NSData(contentsOf: getFile)!, boundary: boundary, uploadFilePath: pathAndFile)
                        
                        // myActivityIndicator.startAnimating();
                        
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
                                if (self.responseString ?? "nada").contains("successfully!") {
                                    DispatchQueue.main.async {
                                        self.totalUploaded += 1
                                    }
                                    item.isUploaded = true
                                    print("\(item.fileName) is uploaded!")
                                }
                                // If all files successfully uploaded, set allFilesUploaded to true
                                if (totalFiles == totalUploaded) {
                                    //                                trip.allFilesUploaded = true
                                    print("All files uploaded!")
                                }
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
                            
                            //                        do {
                            // For debugging?
                            //                            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary
                            //
                            //                            print("-------PRINTING JSON-------")
                            //                            print(json as Any)
                            
                            // From original example?
                            // dispatch_async(dispatch_get_main_queue() is Obj-C
                            //                    dispatch_async(dispatch_get_main_queue(),{
                            //                        self.myActivityIndicator.stopAnimating()
                            //                        self.myImageView.image = nil;
                            //                    })
                            //                    DispatchQueue.main.async {
                            //                        // May need to interact with ImagePicker class
                            //                        self.myImageView.image = nil
                            //                    }
                            
                            //                        } catch
                            //                        {
                            //                            print(error)
                            //                        }
                            
                        }
                        task.resume()
                    } // end if
                } // end for
            }
    }
    
    
    func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, fileData: NSData, boundary: String, uploadFilePath: String) -> Data {
//        let body = NSMutableData() // A dynamic byte buffer that bridges to Data; use NSMutableData when you need reference semantics or other Foundation-specific behavior. (Now recomended to use the new Data struct?)
        
        var body = Data()
        var mimetype = ""
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.append(Data("--\(boundary)\r\n".utf8))
                body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8))
                body.append(Data("\(value)\r\n".utf8))
            }
        }
        
        // Seperate pics and text
        if uploadFilePath.hasSuffix(".heic") {
             mimetype = "image/heic"
        }
        else if uploadFilePath.hasSuffix(".txt") {
             mimetype = "text/plain"
        }
        else if (uploadFilePath.hasSuffix(".jpg") || uploadFilePath.hasSuffix(".jpeg")){
             mimetype = "image/jpg"
        }
                
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(uploadFilePath)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimetype)\r\n\r\n".utf8))
        body.append(fileData as Data)
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
    // nothing! (The working function was renamed to myFileUploadRequest. To prevent faild builds in old views, this dummy function was created)
}

// Not needed for current version of Swift
//extension NSMutableData {
//
//    func appendString(string: String) {
//        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
//        appendData(data!)
//    }
//}
