//
//  FileUploadActor.swift
//  FERN
//
//  Created by Hopp, Dan on 7/30/24.
//

import Foundation
import CryptoKit

actor FileUploadActor {
    
    var fileList: [String] = []
    var localFilePath: URL?
    
    var totalFiles = 0
    var totalProcessed = 0
    var uploadFilePath = ""
    
    func getLocalFilePaths(tripName: String, folderName: String) {
        
        let fm = FileManager.default
//        var path: URL
//        var uploadFilePath: String
        
        var rootDir: URL? {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            return documentsDirectory
        }
        
        // Clear var
        fileList = []
        
        // Get device ID and make path
        uploadFilePath = "\(DeviceUUID().deviceUUID)/trips/\(tripName)/\(folderName)"
        localFilePath = (rootDir?.appendingPathComponent(uploadFilePath))!
        
        // Get a list of all trip files: loop through filenames
        do {
            let items = try fm.contentsOfDirectory(atPath: localFilePath!.path)
            
            // Populate array with filenames
            for item in items {
                fileList.append(item)
            }
            print(fileList)
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print("Directory loop error. Most likely does not exist.")
        }
    }
    
    
    // This function runs on the main thread
    @MainActor func uploadAndShowError(uploadURL: String) async {
        do {
            // Try to download files from the urls
            // The function is suspended here, but the main thread is Not blocked.
            try await uploadTest(fileList: fileList, uploadURL: uploadURL)
        } catch {
            // Show error if occurred, this will run on the main thread
            print("error occurred: \(error.localizedDescription)")
        }
    }
    
    // This function asynchronously uploads data for all passed URLs.
    func uploadTest(fileList: [String], uploadURL: String) async throws {
        let session = URLSession(configuration: .default)
        for item in fileList {
            
            let boundary = "Boundary-\(NSUUID().uuidString)"
            
            let myUrl = NSURL(string: uploadURL)
         
            var request = URLRequest(url:myUrl! as URL)
            request.httpMethod = "POST"

            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            //KeyValuePairs  // IS THIS REQUIRED?
            let paramDict = [
                "firstName"     : "FERN",
                "lastName"      : "Demo",
                "userId"        : "0",
                "fileSavePath"  : "\(uploadFilePath)",
                "fileName"      : "\(item)"
            ]
            
            // path to save the file:
            let pathAndFile = "\(uploadFilePath)/\(item)"
            
            // path to get the file:
            let getFile = self.localFilePath!.appendingPathComponent(item)
            
            // Calculate checksum iOS-side
            let hashed = SHA256.hash(data: NSData(contentsOf: getFile)!)
            let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
            
            // Append hash to params
            let mergeDict = paramDict.merging(["sourceHash":"\(hashString)"]) { (_, new) in new }
            
            // Upload file
            request.httpBody = self.createBodyWithParameters(parameters: mergeDict, filePathKey: "file",
                                                             fileData: NSData(contentsOf: getFile)!,
                                                             boundary: boundary, uploadFilePath: pathAndFile) as Data
    //        var responseString: NSString?
            
            print("Uploading \(item)...")
            
            // If an error occurs, then it will throw, loop will break and function throws,
            // caller must deal with the error.
            do {
                /*
                 func urlSessionUpload (request: URLRequest, postData: Data) async throws -> Data {
                     let (data, _) = try await URLSession.shared.upload(for: request, from: postData, delegate: nil)
                     return data
                 }
                 */
                let (data, response) = try await session.data(for: request)
//            let (data, response) = try await URLSession.shared.data(for: request)
//            URLSession.shared.dataTask(with: request as URLRequest) {
//                data, response, error in
                // Do something with data, response
                // You can even throw from here if you don't like the response...
                print("URL session in test 1x1 starting")
                
//                if error != nil {
//                    print("🔴 error=\(String(describing: error))")
//    //                self.appendToTextEditor(text: "🔴 error=\(String(describing: error))")
//    //                // signal the for loop to continue
//    //                semaphore.signal()
//                    return
//                }
                
                // Print out response object
                //            print("******* response = \(String(describing: response))")
                
                // Print out reponse body
                let statusCode = (response as! HTTPURLResponse).statusCode
                // is 200?
                if statusCode == 200 {
                    
                    // Get response
                    let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
    //                                    print("****** response data = \(self.responseString!)")
                    // Is success?
                    if (responseString ?? "No response string").contains("successfully!") {
    //                    self.upProcessedAndUploadedByOne()
                        print("🟢 \(item) is uploaded!")
    //                    self.appendToTextEditor(text: "🟢 \(fileName) is uploaded!")
                    }
                    
                    // Checksum failed?
                    else if (responseString ?? "No response string").contains("Hashes do not match!") {
    //                    self.totalProcessed += 1
                        print("🔴 Hashes do not match for \(item)!")
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
                
            } catch {
                print(error)
            }
        }
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
