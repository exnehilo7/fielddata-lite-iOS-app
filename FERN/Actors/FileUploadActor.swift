//
//  FileUploadActor.swift
//  FERN
//
//  Created by Hopp, Dan on 7/30/24.
//
// 8/7/2024 May not need actor. FileUploadClass is currently inuse.

import Foundation
import CryptoKit

actor FileUploadActor {
    
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
    var fileList: [String] = []
    var uploadHistoryFileList: [String] = []
    var parameters: [String:String]?
    var tripFolderPath = ""
    var localFilePath: URL?
    var currentTripUploading = ""
    
    func resetVars(){
        consoleText = ""
        currentTripUploading = ""
        totalUploaded = 0
        totalFiles = 0
        totalProcessed = 0
        fileList = []
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
    
    func upProcessedAndUploadedByOne(){
        self.totalProcessed += 1
        self.totalUploaded += 1
    }
    
    func appendToTextEditor(text: String){
        self.consoleText.append(contentsOf: "\n" + text)
    }
 
    func getLocalFilePaths(tripName: String, folderName: String) async {
        
        let fm = FileManager.default
        
        var rootDir: URL? {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            return documentsDirectory
        }
        
        // Get device ID and make path
        tripFolderPath = "\(DeviceUUID().deviceUUID)/trips/\(tripName)/\(folderName)"
        localFilePath = (rootDir?.appendingPathComponent(tripFolderPath))!
        
        // Get a list of all trip files: loop through filenames
        do {
            let items = try fm.contentsOfDirectory(atPath: localFilePath!.path)
            
            // Populate array with filenames
            for item in items {
                fileList.append(item)
            }
            totalFiles = fileList.count
//            print(fileList)
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print("Directory loop error. Most likely does not exist.")
            appendToTextEditor(text: "No files found.")
        }
    }
    
//    func anyFilesToUpload() -> Bool {
//        for tripfile in fileList {
//            if !uploadHistoryFileList.contains(tripfile) {
//                print (tripfile)
//                return true
//            }
//        }
//        return false
//    }
    
    // This function runs on the main thread
    @MainActor func uploadAndShowError(tripName: String, uploadURL: String) async {
        // No files in list, don't do
        if await fileList.count == 0 {return}
        // Create file for upload history, if not exists
        do {
            _ = try await UploadHistoryFile.writeUploadToTextFile(tripOrRouteName: tripName, fileNameUUID: "", fileName: "")
            do {
                // Try to download files from the urls
                // The function is suspended here, but the main thread is Not blocked.
                try await uploadTest(tripName: tripName, fileList: fileList, uploadURL: uploadURL)
            } catch {
                // Show error if occurred, this will run on the main thread
                print("error occurred: \(error.localizedDescription)")
            }
        } catch {
            print("Error creating Upload History file.")
        }
    }
    
    // This function asynchronously uploads data for all passed URLs.
    func uploadTest(tripName: String, fileList: [String], uploadURL: String) async throws {
        isLoading = true
        currentTripUploading = tripName
        let session = URLSession(configuration: .default)
        
        for item in fileList {

            let boundary = "Boundary-\(NSUUID().uuidString)"
            
            let myUrl = NSURL(string: uploadURL)
            
            var request = URLRequest(url:myUrl! as URL)
            request.httpMethod = "POST"
            
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // Don't upload if Low Data Mode is enabled
            //            request.allowsConstrainedNetworkAccess = false
            
            //KeyValuePairs  // IS THIS REQUIRED?
            let paramDict = [
                "firstName"     : "FERN",
                "lastName"      : "Demo",
                "userId"        : "0",
                "fileSavePath"  : "\(tripFolderPath)",
                "fileName"      : "\(item)"
            ]
            
            // path to save the file:
            let pathAndFile = "\(tripFolderPath)/\(item)"
            
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

            // If an error occurs, then it will throw, loop will break and function throws,
            // caller must deal with the error.
            do {
                let (data, response) = try await session.data(for: request)
                // Do something with data, response
                // You can even throw from here if you don't like the response...
                print("URL session in test 1x1 starting")
                
                if !uploadHistoryFileList.contains(item) {
                    print("Uploading \(item)...")
                    appendToTextEditor(text: "Uploading \(item)...")
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
                            // Write time, checksum, and file path & name to upload history file.
                            do {
                                print("item before filewrite call:")
                                print(item)
                                _ = try await UploadHistoryFile.writeUploadToTextFile(tripOrRouteName: tripName, fileNameUUID: "No uuid", fileName: item)
                            } catch { print ("Error writing to upload history after a sucessful save to server.")}
                            
                            print("🟢 \(item) is uploaded!")
                            appendToTextEditor(text: "🟢 \(item) is uploaded!")
                            self.totalUploaded += 1
                        }
                        
                        // Checksum failed?
                        else if (responseString ?? "No response string").contains("Hashes do not match!") {
                            //                    self.totalProcessed += 1
                            print("🔴 Hashes do not match for \(item)!")
                            appendToTextEditor(text: "🔴 Hashes do not match for \(item)!")
                        } else if (responseString ?? "No response string").contains("file exists!") {
                            print("🟡 File already exists.")
                            self.totalUploaded += 1
                            appendToTextEditor(text: "🟡 File already exists.")
                        } else {
                            print(responseString ?? "Response string does not contain 'successfully!' or 'Hashes do not match!' or 'file exists!'")
                            appendToTextEditor(text: (responseString ?? "Response string does not contain text for a successful save, matching hash, or an existing file.") as String)
                        }
                        
                        //                self.finalizeResults(trip: trip)
                        
                    } else {
                        print("🟡 Status code: \(statusCode)")
                        appendToTextEditor(text: "🟡 Status code: \(statusCode)")
                    }
                } else { print("🟠 Filename exists in upload history.")}
            } catch {
                //                if let error = error as? URLError, error.networkUnavailableReason == .constrained {
                //                    print("Low Data Mode is active. This request could not be satisfied.")
                //                    appendToTextEditor(text: "Low Data Mode is active. This request could not be satisfied.")
                //                } else {
                print(error)
                appendToTextEditor(text: "\(error)")
                //                }
            }
        }
        print("🔵 File loop complete.")
        appendToTextEditor(text: "🔵 File loop complete.")
        isLoading = false
    }
    
    func getUploadHistories() async {
        // Run through local folders and make a list of filenames.
        let fm = FileManager.default
        
        var rootDir: URL? {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            return documentsDirectory
        }
        
        // Clear var
        uploadHistoryFileList = []
        
        // Get device ID and make path
        let appRootPath = "\(DeviceUUID().deviceUUID)/trips"
        localFilePath = (rootDir?.appendingPathComponent(appRootPath))!

        // Loop through trips
        do {
            let tripPaths = try fm.contentsOfDirectory(atPath: localFilePath!.path)

            for trip in tripPaths {
                let tripPath = appRootPath + "/\(trip)"
                // Loop through trip subfolders
                do {
                    let tempPath = (rootDir?.appendingPathComponent(tripPath))!
                    let tripSubfolders = try fm.contentsOfDirectory(atPath: tempPath.path)
                    for sub in tripSubfolders {
                        // If trip subfolder is upload history, loop through files within and write file_name to array
                        if sub == "upload_history" {
                            let uploadHistoryPath = tripPath + "/\(sub)"
                            do {
                                let uploadHistFilePath = (rootDir?.appendingPathComponent(uploadHistoryPath))!
                                let historyFiles = try fm.contentsOfDirectory(atPath: uploadHistFilePath.path)
                                for f in historyFiles {
                                    // Open file and split lines into an array
                                    if let lines = try? String(contentsOf: URL(string: "\(uploadHistFilePath)\(f)")!) {
                                        uploadHistoryFileList = lines.components(separatedBy: "\n")
                                        print("Upload History array:")
                                        print(uploadHistoryFileList)
                                        
                                    }
                                }
                            } catch { // Yet another folder error (a YAFE!)
                            }
                        }
                    }
                } catch { // 'Nuther folder error
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
    }
    
}
