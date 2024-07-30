//
//  FileUploadActor.swift
//  FERN
//
//  Created by Hopp, Dan on 7/30/24.
//

import Foundation
import CryptoKit

actor FileUploadActor {
    
    func uploadFile(fileName: String, path: URL, uploadURL: String, uploadFilePath: String, boundary: String) {
        
        let myUrl = NSURL(string: uploadURL)
     
        let request = NSMutableURLRequest(url:myUrl! as URL)
        request.httpMethod = "POST"

        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        //KeyValuePairs  // IS THIS REQUIRED?
        let paramDict = [
            "firstName"     : "FERN",
            "lastName"      : "Demo",
            "userId"        : "0",
            "fileSavePath"  : "\(uploadFilePath)",
            "fileName"      : "\(fileName)"
        ]
        
        // path to save the file:
        let pathAndFile = "\(uploadFilePath)/\(fileName)"
        
        // path to get the file:
        let getFile = path.appendingPathComponent(fileName)
        
        // Calculate checksum iOS-side
        let hashed = SHA256.hash(data: NSData(contentsOf: getFile)!)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        
        // Append hash to params
        let mergeDict = paramDict.merging(["sourceHash":"\(hashString)"]) { (_, new) in new }
        
        // Upload file
        request.httpBody = self.createBodyWithParameters(parameters: mergeDict, filePathKey: "file",
                                                         fileData: NSData(contentsOf: getFile)!,
                                                         boundary: boundary, uploadFilePath: pathAndFile)
        
//        var responseString: NSString?
        
        print("Uploading \(fileName)...")
        
        // Upload file
        URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            print("URL session in uploadFile stating ")
            
            if error != nil {
                print("🔴 error=\(String(describing: error))")
//                self.appendToTextEditor(text: "🔴 error=\(String(describing: error))")
//                // signal the for loop to continue
//                semaphore.signal()
                return
            }
            
            // Print out response object
            //            print("******* response = \(String(describing: response))")
            
            // Print out reponse body
            let statusCode = (response as! HTTPURLResponse).statusCode
            // is 200?
            if statusCode == 200 {
                
                // Get response
                let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
//                                    print("****** response data = \(self.responseString!)")
                // Is success?
                if (responseString ?? "No response string").contains("successfully!") {
//                    self.upProcessedAndUploadedByOne()
                    print("🟢 \(fileName) is uploaded!")
//                    self.appendToTextEditor(text: "🟢 \(fileName) is uploaded!")
                }
                
                // Checksum failed?
                else if (responseString ?? "No response string").contains("Hashes do not match!") {
//                    self.totalProcessed += 1
                    print("🔴 Hashes do not match for \(fileName)!")
//                    self.appendToTextEditor(text: "🔴 Hashes do not match for \(fileName)!")
                }
                
//                self.finalizeResults(trip: trip)
                
                // signal the for loop to continue
//                semaphore.signal()
            } else {
                print("🟡 Status code: \(statusCode)")
//                self.appendToTextEditor(text: "🟡 Status code: \(statusCode)")
//                semaphore.signal()
            }
            
        }.resume()
        // Hit pause
//        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
   
    func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, fileData: NSData, boundary: String, uploadFilePath: String) -> Data {
        
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
    
}
