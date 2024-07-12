//
//  FileUploadClass.swift
//  FERN
//
//  Created by Hopp, Dan on 6/28/24.
//

import Foundation
import SwiftUI
import CryptoKit

@Observable class FileUploadClass {
    
    var isLoading = false
    var totalUploaded = 0
    var totalFiles = 0
    var totalProcessed = 0
    var continueImageUpload = false
    var showCesiumAndContinueAlert = false
    var responseString: NSString?
    var allFilesProcessed = false
    var consoleText = ""
    var showUploadButton = false
    var showPopover = false
    var MetadataFileList: [String] = []
    var ImageFileList: [String] = []
    var ScoringFileList: [String] = []
//    let boundary = "Boundary-\(NSUUID().uuidString)"
    
    // Move into an init or class initialization any vars that will never change on class creation, such as myUrl = NSURL(string: uploadURL)
    
    func resetVars(){
        consoleText = ""
        totalUploaded = 0
        totalFiles = 0
        totalProcessed = 0
    }
    
    func getLocalFilePaths(tripName: String) {
        
        let fm = FileManager.default
        var path: URL
        var uploadFilePath: String
        
        var rootDir: URL? {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            return documentsDirectory
        }
        
        // Clear vars
        MetadataFileList = []
        ImageFileList = []
        ScoringFileList = []
        
        // Get device ID and make path
        uploadFilePath = "\(DeviceUUID().deviceUUID)/trips/\(tripName)"
        path = (rootDir?.appendingPathComponent(uploadFilePath))!
        
        // Get a list of all trip files: loop through filenames
        do {
            let items = try fm.contentsOfDirectory(atPath: path.path)
            
            // Populate array with filenames
            for item in items {
                if item.contains("Scoring") {
                    ScoringFileList.append(item)
                }
                else
                if item.contains(".heic") || item.contains(".jpg") || item.contains(".jpeg") {
                    ImageFileList.append(item)
                }
                else {
                    MetadataFileList.append(item)
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print("Directory loop error")
        }
    }
    
    // Create the first part of the request. Data and closing boundaries will be added later on.
    func createBaseFileUploadRequest(uploadURL: String) {
        let myUrl = NSURL(string: uploadURL)
     
        let request = NSMutableURLRequest(url:myUrl! as URL)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(NSUUID().uuidString)"

        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    }
    
    
    // HAVE SEVERAL UPLOAD FUNCTIONS, EACH FOR ITS OWN FILETYPE? That way an upload can be called at any point in the app's business flow.
    func beginFileUpload(tripName: String, uploadURL: String, mapUILayout: String) async
    {
        
        // Set var
        isLoading = true

        // ---- WRAPPED IN A FUNCTION, NEED TO REPLACE WITH THE FUNCTION --------------------------------
        // Set endpoint
        let myUrl = NSURL(string: uploadURL)
        let request = NSMutableURLRequest(url:myUrl! as URL)
        request.httpMethod = "POST"
        let boundary = self.generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        // ----------------------------------------------------------------------------------------------

        // ---- WRAPPED IN A FUNCTION, NEED TO REPLACE WITH THE FUNCTION --------------------------------
            // FILE LOOP
            let fm = FileManager.default
            // Get app's root dir
            var rootDir: URL? {
                guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
                return documentsDirectory
            }
            var path: URL
            var uploadFilePath: String
            var fileList: [String] = []
            // Get device ID and make path
            uploadFilePath = "\(DeviceUUID().deviceUUID)/trips/\(tripName)"
            path = (rootDir?.appendingPathComponent(uploadFilePath))!
            // Get a list of all trip files: loop through filenames
            do {
                let items = try fm.contentsOfDirectory(atPath: path.path)
                // Populate array with filenames
                for item in items {
                    // If uploading scoring files, get only those
                    if mapUILayout == "none" {
                        fileList.append(item)
                    }
                    else if mapUILayout == "scoring" {
                        if item.contains("Scoring") {
                            fileList.append(item)
                        }
                    }
                }
            } catch {
                // failed to read directory – bad permissions, perhaps?
                print("Directory loop error")
            }
        // ----------------------------------------------------------------------------------------------
        
        // get total number of files
        self.totalFiles = fileList.count
        
        print(self.totalFiles)
        
        print(continueImageUpload)
        
        if !continueImageUpload {
            // upload txt file first
            // loop through files in trip array
            for item in fileList {
                if item.contains(".csv") {
                    await processFile(item: item, uploadFilePath: uploadFilePath,
                                      boundary: boundary, request: request,
                                      path: path, uploadURL: uploadURL)
                    
                    // If file name contains "Scoring", hold off on calling insert into database function until the python script and the database tables are updated to handle a scoring CSV.
                    if item.contains("Scoring") {
                        print("ℹ️ Scoring files are uploaded/re-uploaded.")
                        appendToTextEditor(text: "ℹ️ Scoring files are uploaded/re-uploaded.")
                    }
                    else {
                        if await !insertUploadedFileDataIntoDatabase(uploadURL: uploadURL){
                            print("🔵 Database insert complete. Check the database for results.")
                            appendToTextEditor(text: "🔵 Database insert complete. Check the database for results.")
                        }
                    }
                    
                    // Give user option to look at webpage or to continue with picture uploads
                    showCesiumAndContinueAlert = true
                    
                }
            }
        }
        
        // Upload non-txt files
        // loop through files in trip array
        if continueImageUpload {
            for item in fileList {
                if !item.contains(".csv") {
                    print("Item does not contain .csv")
                    await processFile(item: item, uploadFilePath: uploadFilePath,
                                      boundary: boundary, request: request,
                                      path: path, uploadURL: uploadURL)
                }
                else {
                    print(item)
                }
            }
            print("ℹ️ Trip file array loop complete.")
            appendToTextEditor(text: "ℹ️ Trip file array loop complete.")
            continueImageUpload = false
        }
        
        isLoading = false
    }
    
    func processFile(item: String, uploadFilePath: String,
                             boundary: String, request: NSMutableURLRequest,
                             path: URL, uploadURL: String) async {
        
        // Let user know file is processing
        print("Processing next...")
        appendToTextEditor(text: "Processing next...")
        
        //KeyValuePairs
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
        let getFile = path.appendingPathComponent(item)
        
        // Toggle thread pauses until URLSessions complete
        let semaphore = DispatchSemaphore(value: 0)
        
        // If file is a scoring CSV, go ahead and re-upload if it already exists
        if !item.contains("Scoring") {
            print("item does not contain 'Scoring'")
            // Is uploaded?
            if await !doesFileExist(fileName: item, params: paramDict, semaphore: semaphore, uploadURL: uploadURL) {
                print("File does not exist, calling calcChecksumAndUploadFile.")
                calcChecksumAndUploadFile(fileName: item, boundary: boundary, request: request, getFile: getFile, pathAndFile: pathAndFile, paramDict: paramDict, semaphore: semaphore)
            }
        }
        // Contine upload if already exists
        else {
            calcChecksumAndUploadFile(fileName: item, boundary: boundary, request: request, getFile: getFile, pathAndFile: pathAndFile, paramDict: paramDict, semaphore: semaphore)
        }
    }
    
    func calcChecksumAndUploadFile(fileName: String, boundary: String, request: NSMutableURLRequest, getFile: URL, pathAndFile: String, paramDict: [String : String], semaphore: DispatchSemaphore) {
        
        // Calculate checksum iOS-side
        let hashed = SHA256.hash(data: NSData(contentsOf: getFile)!)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        
        // Append hash to params
        let mergeDict = paramDict.merging(["sourceHash":"\(hashString)"]) { (_, new) in new }
        
        // Upload file
        request.httpBody = self.createBodyWithParameters(parameters: mergeDict, filePathKey: "file",
                                                         fileData: NSData(contentsOf: getFile)!,
                                                         boundary: boundary, uploadFilePath: pathAndFile)
        uploadFile(fileName: fileName, request: request, semaphore: semaphore)
    }
    
    func doesFileExist(fileName: String, params: [String:String], semaphore: DispatchSemaphore, uploadURL: String) async -> Bool {
        
        print("doesFileExist is firing!")
        
        var exists = false
        
        // Apparently to do a upload POST with no file, a "clean" URL and the do..let..try..await URLSession.shared.upload is needed?
        guard let url: URL = URL(string: uploadURL) else {
            Swift.print("invalid URL")
            return exists
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let fileSavePath:String = params["fileSavePath"] ?? ""
        let fileName:String = params["fileName"] ?? ""
        
        let postString = "fileSavePath=\(fileSavePath)&fileName=\(fileName)"
        
        let postData = postString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request as URLRequest, from: postData!, delegate: nil)
            
            let statusCode = (response as! HTTPURLResponse).statusCode
            // is 200?
            if statusCode == 200 {
                
                // Get response
                self.responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
                // Exists?
                if (self.responseString ?? "No response string").contains("file exists!") {
                    print("🟠 \(fileName) already exists.")
                    appendToTextEditor(text: "🟠 \(fileName) already exists.")
                    upProcessedAndUploadedByOne()
                    exists = true
                }
                
//                finalizeResults(trip: trip)
                
            } else {
                print("🟡 Status code: \(statusCode)")
                appendToTextEditor(text: "🟡 Status code: \(statusCode)")
            }
        } catch let error as NSError {
            NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
        }
        
        return exists
    }
    
    func uploadFile(fileName: String, request: NSMutableURLRequest, semaphore: DispatchSemaphore) {
        
        print("Uploading \(fileName)...")
        
        // Upload file
        URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            print("URL session in uploadFile stating ")
            
            if error != nil {
                print("🔴 error=\(String(describing: error))")
                self.appendToTextEditor(text: "🔴 error=\(String(describing: error))")
                // signal the for loop to continue
                semaphore.signal()
                return
            }
            
            // Print out response object
            //            print("******* response = \(String(describing: response))")
            
            // Print out reponse body
            let statusCode = (response as! HTTPURLResponse).statusCode
            // is 200?
            if statusCode == 200 {
                
                // Get response
                self.responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
//                                    print("****** response data = \(self.responseString!)")
                // Is success?
                if (self.responseString ?? "No response string").contains("successfully!") {
                    self.upProcessedAndUploadedByOne()
                    print("🟢 \(fileName) is uploaded!")
                    self.appendToTextEditor(text: "🟢 \(fileName) is uploaded!")
                }
                
                // Checksum failed?
                else if (self.responseString ?? "No response string").contains("Hashes do not match!") {
                    self.totalProcessed += 1
                    print("🔴 Hashes do not match for \(fileName)!")
                    self.appendToTextEditor(text: "🔴 Hashes do not match for \(fileName)!")
                }
                
//                self.finalizeResults(trip: trip)
                
                // signal the for loop to continue
                semaphore.signal()
            } else {
                print("🟡 Status code: \(statusCode)")
                self.appendToTextEditor(text: "🟡 Status code: \(statusCode)")
                semaphore.signal()
            }
            
        }.resume()
        // Hit pause
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
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
    
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    // Not used anywhere atm:
    func setResponseMsgToBlank() {
            DispatchQueue.main.async { [self] in
                self.responseString = "None"
            }
    }
    
    func upProcessedAndUploadedByOne(){
        self.totalProcessed += 1
        self.totalUploaded += 1
    }
    
    // To make FileUploadClass more universal, the SDTrip function passes were removed and this code was moved to UploadFilesView.
//    func finalizeResults(trip: SDTrip){
//        // If all files uploaded, set allFilesUploaded = true
//        if (totalFiles == totalUploaded) {
//            trip.allFilesUploaded = true
//            print("🔵 All files uploaded.")
//            appendToTextEditor(text: "🔵 All files uploaded.")
//        }
//        // If all files processed, set allFilesProcessed = true
//        if (totalFiles == totalProcessed) {
//            self.allFilesProcessed = true
//        }
//    }
    
    func appendToTextEditor(text: String){
        self.consoleText.append(contentsOf: "\n" + text)
    }
    

    func insertUploadedFileDataIntoDatabase(uploadURL: String) async -> Bool {
   
        var complete = false
        
        guard let url: URL = URL(string: uploadURL) else {
            Swift.print("invalid URL")
            return complete
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "insertIntoDB=true"
        
        let postData = postString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request as URLRequest, from: postData!, delegate: nil)
            let statusCode = (response as! HTTPURLResponse).statusCode
            // is 200?
            if statusCode == 200 {
                print("🟣 Calling function to insert trip into the database. Check database for results.")
                appendToTextEditor(text: "🟣 Calling function to insert trip into the database. Check database for results.")
                self.responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
//                print("****** response data = \(self.responseString!)")
                complete = true
                return complete
            } else {
                print("🟡 Status code: \(statusCode)")
                appendToTextEditor(text: "🟡 Status code: \(statusCode)")
            }
          } catch let error as NSError {
              NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
          }
                                                                      
        return complete
    }
}
