//
//  PrepFilesForUploadActor.swift
//  FERN
//
//  Created by Hopp, Dan on 7/30/24.
//

import Foundation
import CryptoKit

actor PrepFilesForUploadActor {
    
    var fileList: [String] = []
    var request: NSMutableURLRequest?
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
    
    
    
    func beginFileUpload(tripName: String, uploadURL: String) async {
        // No action if no files
        if fileList.count == 0 {return}
        
        let boundary = "Boundary-\(NSUUID().uuidString)"
        
//        await createBaseFileUploadRequest(uploadURL: uploadURL, boundary: boundary)
        
        // get total number of files
        totalFiles = fileList.count
        
        print(totalFiles)

        for item in fileList {
            await processMetadataFile(fileName: item, uploadFilePath: uploadFilePath,
                        boundary: boundary, //request: request,
                        path: localFilePath!, uploadURL: uploadURL)
        }

    }
    
    // Create the first part of the request. Data and closing boundaries will be added later on.
//    func createBaseFileUploadRequest(uploadURL: String, boundary: String) async {
//        let myUrl = NSURL(string: uploadURL)
//     
//        let request = NSMutableURLRequest(url:myUrl! as URL)
//        request.httpMethod = "POST"
//
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//    }
    
    func processMetadataFile(fileName: String, uploadFilePath: String,
                             boundary: String, //request: NSMutableURLRequest,
                             path: URL, uploadURL: String) async {
        
//        let myUrl = NSURL(string: uploadURL)
//     
//        let request = NSMutableURLRequest(url:myUrl! as URL)
//        request.httpMethod = "POST"
//
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Let user know file is processing
        //        print("Processing next...")
        //        appendToTextEditor(text: "Processing next...")
        
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
        
        // Toggle thread pauses until URLSessions complete
//        let semaphore = DispatchSemaphore(value: 0)
        
//        await calcChecksum(fileName: item, boundary: boundary, request: request, getFile: getFile, pathAndFile: pathAndFile, paramDict: paramDict, semaphore: semaphore)
        
        let upload = FileUploadActor()
        
        Task.detached{
            await upload.uploadFile(fileName: fileName, path: self.localFilePath!, uploadURL: uploadURL, uploadFilePath: uploadFilePath, boundary: boundary) //, semaphore: semaphore)
        }
    }
    
//    func calcChecksum(fileName: String, boundary: String, request: NSMutableURLRequest, getFile: URL, pathAndFile: String, paramDict: [String : String], semaphore: DispatchSemaphore) async {
//        
//        // Calculate checksum iOS-side
//        let hashed = SHA256.hash(data: NSData(contentsOf: getFile)!)
//        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
//        
//        // Append hash to params
//        let mergeDict = paramDict.merging(["sourceHash":"\(hashString)"]) { (_, new) in new }
//        
//        // Upload file
//        request.httpBody = self.createBodyWithParameters(parameters: mergeDict, filePathKey: "file",
//                                                         fileData: NSData(contentsOf: getFile)!,
//                                                         boundary: boundary, uploadFilePath: pathAndFile)
//    }
    
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
