//
//  FileUploadClass.swift
//  FERN
//
//  Created by Hopp, Dan on 6/28/24.
//

import Foundation
import SwiftUI
import CryptoKit


// For upload history files
struct UploadedItem: Identifiable {
    let id = UUID()
    var fileName = ""
    var checksum = ""
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(fileName, forKey: .fileName)
        try container.encode(checksum, forKey: .checksum)
    }
    
    init(fileName: String = "",
         checksum: String = "") {
        self.fileName = fileName
        self.checksum = checksum
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        fileName = try container.decode(String.self, forKey: .fileName)
        checksum = try container.decode(String.self, forKey: .checksum)
    }
}
extension UploadedItem: Codable {
    enum CodingKeys: CodingKey {
        case fileName, checksum
    }
}

//struct UploadedItem: Identifiable {
//    let id = UUID()
//    var fileName = ""
//    var checksum = ""
//}


@MainActor
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
//    var showPopover = false
    var tripsSubfolders: [String] = [] // Trip and route names within the trips folder
    var fileList: [String] = []
//    var uploadHistoryFileList: [String] = [] // TO BE REPLACED BY NEW STRUCT
    var allUploadedFiles: [UploadedItem] = []
    var currentSubfolderFiles: [UploadedItem] = []
    var parameters: [String:String]?
    var tripFolderPath = ""
    var localFilePath: URL?
    var currentTripUploading = ""
    
    var network = NetworkMonitorClass()
    var showUnpluggedBatteryAlert = false
    var showNoNetworkAlert = false
    var showExpensiveNetworkAlert = false
    var showConstrainedNetworkAlert = false
    var networkIsGoodToGo = false
    var tea = TextEditorAppend()
    
    func resetVars() async {
        currentTripUploading = ""
        totalUploaded = 0
        totalFiles = 0
        totalProcessed = 0
        fileList = []
    }
    func resetConsoleText() async {
        consoleText = ""
    }
    
    // 17-OCT-2024 - Not used atm.
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
                    consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "🟠 \(fileName) already exists.")
                    upProcessedAndUploadedByOne()
                    exists = true
                }
            } else {
                print("🟡 Status code: \(statusCode)")
                consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "🟡 Status code: \(statusCode)")
            }
        } catch let error as NSError {
            NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
        }
        
        return exists
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
    
    func setShowUploadButtonToFalse() {
        showUploadButton = false
    }
    func setShowUploadButtonToTrue() {
        showUploadButton = true
    }
//    func setShowPopoverToTrue(){
//        showPopover = true
//    }
//    
//    func appendToTextEditor(oldText: consoleText, newText: String){
//        self.consoleText.append(contentsOf: "\n" + text)
//    }
    
//    func clearUploadHistoryList() async {
//        // Clear var
//        uploadHistoryFileList = []
//    }
    
    func clearUploadHistoryItemList() async {
        // Clear var
        allUploadedFiles = []
    }

    
    // ASYNC FUNCTIONS ---------------------------------------------------------------------------------------------
    func checkForUploads(sdTrips: [SDTrip], uploadURL: String) async {  // MAY NOT BE NEEDED ANYMORE?
        await resetVars()
        await resetConsoleText()
        // Get upload history
//        await clearUploadHistoryList()
        await clearUploadHistoryItemList()
        await getUploadHistories()
        
        // Make list of ALL trip and route files
        await getTripAndRouteNames()
        for subfolder in tripsSubfolders {
            await getLocalFilePathsForTripOnDevice(tripName: subfolder, folderName: "metadata")
            await getLocalFilePathsForTripOnDevice(tripName: subfolder, folderName: "scoring")
            await getLocalFilePathsForTripOnDevice(tripName: subfolder, folderName: "images")
        }
        
        // See if a file doesn't exist in Upload History
        if await anyFilesToUpload() {
            print("There are files to upload!")
            consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "There are files to upload!")
            // Check network connections
            await isNetworkGood(sdTrips: sdTrips, uploadURL: uploadURL)
        } else {
            print("No new files to upload")
            consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "No new files to upload.")
        }
    }
    
    func getLocalFilePathsForTripOnDevice(tripName: String, folderName: String) async {
        
        var rootDir: URL? {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            return documentsDirectory
        }
        
        // Get device ID and make path for all trips and routes
        // Get all trip and route subfolder names
        
        tripFolderPath = "\(DeviceUUID().deviceUUID)/trips/\(tripName)/\(folderName)"
        localFilePath = (rootDir?.appendingPathComponent(tripFolderPath))!
        
        // Get a list of all trip files: loop through filenames
        do {
            try await makeFileList(tripName: tripName, localFilePath: localFilePath!)
        } catch {
            // failed to read directory – bad permissions, perhaps?
//            print("Directory loop error. Most likely does not exist.")
//            consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "No files found.")
        }
    }
    
    func makeFileList(tripName: String, localFilePath: URL) async throws {
        
        let fm = FileManager.default
        let items = try fm.contentsOfDirectory(atPath: localFilePath.path)
        
        // Populate array with filenames
        for item in items {
            fileList.append(item)
        }
        totalFiles = fileList.count
        
        // Populate currentSubfolderFiles to not lose any previously uploaded files
//        let jsonData = try Data(contentsOf: URL(string: "\(DeviceUUID().deviceUUID)/trips/\(tripName)/upload_history/\(tripName)_Upload_History.json")!)
//        let jsonDecoder = JSONDecoder()
//        var itemResults = try jsonDecoder.decode([UploadedItem].self, from: jsonData)
//        
//        for result in itemResults {
//            currentSubfolderFiles.append(
//                UploadedItem(fileName: result.fileName,
//                             checksum: result.checksum)
//            )
//        }
//        itemResults = [UploadedItem]()
    }
    
    
    // Should not need this anymore since only changed or new files will be uploaded
     func anyFilesToUpload() async -> Bool {
//        for tripfile in fileList {
////            if !uploadHistoryFileList.contains(tripfile) {
////                return true
////            }
//            
//            var uploadedFile = allUploadedFiles.filter{$0.fileName == tripfile}
//            
//            let getFile = self.localFilePath!.appendingPathComponent(tripfile)
//            let hashed = SHA256.hash(data: NSData(contentsOf: getFile)!)
//            let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
//            
//            // Has file checksum changed?
//            if uploadedFile.count > 0 {
//                if uploadedFile[0].checksum != hashString {
//                    return true
//                }
//            }
//            else {
//                return true
//            }
//        }
//        return false
         return true
    }
    
    func isNetworkGood(sdTrips: [SDTrip], uploadURL: String) async {
        // Check network connections
        if network.isActive {
            consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "Network is active.")
            switch UIDevice.current.batteryState {
            case .unplugged:
                showUnpluggedBatteryAlert = true
            default:
                await checkForExpensiveNetwork(sdTrips: sdTrips, uploadURL: uploadURL)
            }
        } else {
            showNoNetworkAlert = true
        }
    }
    
    func checkForExpensiveNetwork(sdTrips: [SDTrip], uploadURL: String) async {
        showUnpluggedBatteryAlert = false
        if network.isExpensive {
            consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "Network is expensive.")
            showExpensiveNetworkAlert = true
        } else {await loopThroughTripsAndUpload(sdTrips: sdTrips, uploadURL: uploadURL)}
    }
    
    func loopThroughTripsAndUpload(sdTrips: [SDTrip], uploadURL: String) async {
        var itemIsTrip = false
        
        /* Loop through trips and upload any new/missed files. If the subfolder name under the trips folder is in sdTrips, keep uploading its CSVs and skip the images until the trip is marked as complete. Once complete, write to the history file to prevent future uploads.
          For a route, always upload its CSVs until it's decided how to handle "completed" route data acquisition. */
        for subfolder in tripsSubfolders {
            // Clear array of subfolder's uploaded files
            currentSubfolderFiles = []
            
            print("--- Processing \(subfolder)'s files ---")
            consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "--- Processing \(subfolder)'s files ---")
            
            // Is name in sdTrips?
            for trip in sdTrips {
                if trip.name == subfolder {
                    print("  \(subfolder) is a TRIP")
                    consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  \(subfolder) is a TRIP")
                    itemIsTrip = true
                    
                    // If complete, ulpload all file types
                    if trip.isComplete {
                        print("  Trip is marked as complete!")
                        consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  Trip is marked as complete!")
                        
                        await resetVars()
                        await getLocalFilePathsForTripOnDevice(tripName: trip.name, folderName: "metadata")
                        await uploadAndShowError(tripName: trip.name, uploadURL: uploadURL, folderName: "metadata")//,  writeToUploadHistory: true)
                        await resetVars()
                        await getLocalFilePathsForTripOnDevice(tripName: trip.name, folderName: "scoring")
                        await uploadAndShowError(tripName: trip.name, uploadURL: uploadURL, folderName: "scoring")//, writeToUploadHistory: true)
                        await resetVars()
                        await getLocalFilePathsForTripOnDevice(tripName: trip.name, folderName: "images")
                        await uploadAndShowError(tripName: trip.name, uploadURL: uploadURL, folderName: "images")//, writeToUploadHistory: true)
                    }
                    else {
                        // Upload scoring and metadata
//                        await resetVars()
//                        await getLocalFilePathsForTripOnDevice(tripName: trip.name, folderName: "metadata")
//                        await uploadAndShowError(tripName: trip.name, uploadURL: uploadURL, folderName: "metadata",  writeToUploadHistory: false)
//                        await resetVars()
//                        await getLocalFilePathsForTripOnDevice(tripName: trip.name, folderName: "scoring")
//                        await uploadAndShowError(tripName: trip.name, uploadURL: uploadURL, folderName: "scoring", writeToUploadHistory: false)
                        // No image files
                        print("  Trip is not marked complete, skipping files...")
                        consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  Trip is not marked complete, skipping files...")
                    }
                }
            }
            
            // Processes as route if subfolder name not a trip
            if !itemIsTrip {
                print("  \(subfolder) is a ROUTE")
                consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  \(subfolder) is a ROUTE")
                await resetVars()
                await getLocalFilePathsForTripOnDevice(tripName: subfolder, folderName: "metadata")
                await uploadAndShowError(tripName: subfolder, uploadURL: uploadURL, folderName: "metadata")//,  writeToUploadHistory: true)
                await resetVars()
                await getLocalFilePathsForTripOnDevice(tripName: subfolder, folderName: "scoring")
                await uploadAndShowError(tripName: subfolder, uploadURL: uploadURL, folderName: "scoring")//, writeToUploadHistory: true)
                await resetVars()
                await getLocalFilePathsForTripOnDevice(tripName: subfolder, folderName: "images")
//                print(currentSubfolderFiles)
                await uploadAndShowError(tripName: subfolder, uploadURL: uploadURL, folderName: "images")//, writeToUploadHistory: true)
            }
            
            // Write uploaded files to a JSON file
            if !currentSubfolderFiles.isEmpty {
                let jsonEncoder = JSONEncoder()
                let jsonData = try? jsonEncoder.encode(currentSubfolderFiles)
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsDirectory.appendingPathComponent("\(DeviceUUID().deviceUUID)/trips/\(subfolder)/upload_history/\(subfolder)_Upload_History.json")
                try? jsonData?.write(to: fileURL)
            }
            
            print("\(subfolder) is complete.")
            consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "\(subfolder) is complete.")
            
            // Time for next subfolder name
            itemIsTrip = false
            
        }
        // Insert new data into the database
        print("🟪 Launching .py script to refresh database...")
        consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "🟪 Launching .py script to refresh database...")
//        _ = await insertUploadedFileDataIntoDatabase(uploadURL: uploadURL)
        
        print("🔵 Upload process finished.")
        consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "🔵 Upload process finished.")
    }
    
    func printProcessingFileType(fileType: String) {
        print("  Processing \(fileType) files...")
        consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  Processing \(fileType) files...")
    }
    
    // This function runs on the main thread
    func uploadAndShowError(tripName: String, uploadURL: String, folderName: String) async {
        
        // If no files in list, don't do
        if fileList.count == 0 {
            print("  No \(folderName) files found, skipping...")
            consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  No \(folderName) files found, skipping...")
            return
        }
        
        printProcessingFileType(fileType: folderName)
        
        // Create file for upload history, if not exists
//        do {
//            _ = try await UploadHistoryFile.writeUploadToTextFile(tripOrRouteName: tripName, fileNameUUID: "", fileName: "")
            do {
                // The function is suspended here, but the main thread is not blocked.
                try await uploadAsync(tripName: tripName, fileList: fileList, uploadURL: uploadURL, folderName: folderName)//, writeToHistory: writeToUploadHistory)
            } catch {
                // Show error if occurred, this will run on the main thread
                print("error occurred: \(error.localizedDescription)")
            }
//        } catch {
//            print("Error creating Upload History file.")
//        }
    }
    
    // This function asynchronously uploads data for all passed URLs.
    func uploadAsync(tripName: String, fileList: [String], uploadURL: String, folderName: String) async throws {
        isLoading = true
        currentTripUploading = tripName
        let session = URLSession(configuration: .default)
        
        /*  If a trip is NOT complete, do not add CSVs to a Upload History file. (Keep uploading/reuploading (Also handled in the PHP script)). If a trip is complete, add CSV files to Upload History.
            Always upload new pics and write to Upload History.
            */
//        var writeToUploadHistory = true
//        if tripIsComplete || folderName == "images" {
//            writeToUploadHistory = true
//        }
        
        for item in fileList {
            
            var updateChecksum = false
            
//            if !uploadHistoryFileList.contains(item) {
            
            // path to get the file:
            let getFile = self.localFilePath!.appendingPathComponent(item)
            
            // Calculate checksum iOS-side
            let hashed = SHA256.hash(data: NSData(contentsOf: getFile)!)
            let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
            
            // Has file already been uploaded?
            var uploadedFile = allUploadedFiles.filter{$0.fileName == item}
            if uploadedFile.count > 0 {
                // If checksum is same, go to next
                print("FILE IS IN ALLUPLOADEDFILES!")
                if uploadedFile[0].checksum == hashString {
                    print("checksums match")
                    self.totalUploaded += 1
                    print("  🟠 Filename exists in upload history.")
                    // Write to currentSubfolderFiles to not lose any previously uploaded files
                    currentSubfolderFiles.append(
                        UploadedItem(fileName: item,
                                     checksum: hashString)
                    )
                    continue
                } else {
                    // mark for update after upload
                    updateChecksum = true
                }
            }
            
            // If file hasn't been uploaded or checksum is different, continue with upload
            
                print("  Uploading \(item)...")
                consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  Uploading \(item)...")

                let boundary = "Boundary-\(NSUUID().uuidString)"
                
                let myUrl = NSURL(string: uploadURL)
                
                var request = URLRequest(url:myUrl! as URL)
                request.httpMethod = "POST"
                
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                //KeyValuePairs
                let paramDict = [
                    "firstName"     : "FERN",
                    "lastName"      : "Demo",
                    "userId"        : "0",
                    "fileSavePath"  : "\(tripFolderPath)",
                    "fileName"      : "\(item)"
                ]
                
                // path to save the file:
                let pathAndFile = "\(tripFolderPath)/\(item)"
            
                
                // Append hash to params
                let mergeDict = paramDict.merging(["sourceHash":"\(hashString)"]) { (_, new) in new }
                
                // Upload file
                request.httpBody = self.createBodyWithParameters(parameters: mergeDict, filePathKey: "file",
                                                                 fileData: NSData(contentsOf: getFile)!,
                                                                 boundary: boundary, uploadFilePath: pathAndFile) as Data

                do {
                    let (data, response) = try await session.data(for: request)
   
                        // Print out response object
                        //            print("******* response = \(String(describing: response))")
                        
                        let statusCode = (response as! HTTPURLResponse).statusCode
                        // is 200?
                        if statusCode == 200 {
                            
                            // Get response
                            let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
                            //                                    print("****** response data = \(self.responseString!)")
                            // Is success?
                            if (responseString ?? "No response string").contains("successfully!") {
                                // If new file, write file name and checksum to upload history file.
                                if !updateChecksum {
//                                    await writeToUploadHistory(tripOrRouteName: tripName, fileNameUUID: "No uuid", fileName: item, checksum: hashString)
                                    currentSubfolderFiles.append(UploadedItem(fileName: item, checksum: hashString))
                                } else {
                                // If checksum differnet, update vaue
                                    uploadedFile[0].checksum = hashString
                                }
                                
                                print("  🟢 \(item) is uploaded!")
                                consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  🟢 \(item) is uploaded!")
                                self.totalUploaded += 1
                            }
                            
                            // Checksum failed?
                            else if (responseString ?? "No response string").contains("Hashes do not match!") {
                                print("  🔴 Hashes do not match for \(item)!")
                                consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  🔴 Hashes do not match for \(item)!")
                            // File exists? 17-OCT-2024: PHP NO LONGER CHECKING IF FILE EXISTS ON SERVER
//                            } //else if (responseString ?? "No response string").contains("file exists!") {
//                                // To circumvent a bug where a file is written to the server but its name fails to write to the local history file, write to local history if exists:
//                                await writeToUploadHistory(tripOrRouteName: tripName, fileNameUUID: "No uuid", fileName: item, checksum: hashString)
//                                print("  🟡 File already exists.")
//                                self.totalUploaded += 1
//                                consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  🟡 File already exists.")
                                
                            } else {
                                print(responseString ?? "  Response string does not contain 'successfully!' or 'Hashes do not match!' or 'file exists!'")
                                consoleText = tea.appendToTextEditor(oldText: consoleText, newText: (responseString ?? "  Response string does not contain text for a successful save, matching hash, or an existing file.") as String)
                            }
                            
                        } else {
                            print("  🟡 Status code: \(statusCode)")
                            consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  🟡 Status code: \(statusCode)")
                        }
                } catch {
                    print(error)
                    consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  \(error)")
                }
            } //else {
//                self.totalUploaded += 1
//                print("  🟠 Filename exists in upload history.")
//            }
//        }
        
//        print("After uploadAsync loop:")
//        print(currentSubfolderFiles)
        
        
        print("  \(folderName.capitalized) process complete.")
        consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  \(folderName.capitalized) process complete.")
        isLoading = false
    }
    
    func writeToUploadHistory(tripOrRouteName: String, fileNameUUID: String, fileName: String, checksum: String) async {
//        do {
//            _ = try await UploadHistoryFile.writeUploadToTextFile(tripOrRouteName: tripOrRouteName, fileNameUUID: fileNameUUID, fileName: fileName)
//        } catch {
//            print ("  🔴 Error writing to upload history after a sucessful save to server.")
//            consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  🔴 Error writing to upload history after a sucessful save to server.")
//        }
        
        // ADD INFO TO ARRAY FOR JSON CREATION AND SAVE AFTER A TRIP/ROUTE'S LOOP IS COMPLETE?
        currentSubfolderFiles.append(UploadedItem(fileName: fileName, checksum: checksum))
    }
    
    func getUploadHistories() async {
        // For UploadedItem JSONs
        
        
        // Run through local folders and make a list of filenames.
        let fm = FileManager.default
        
        var rootDir: URL? {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            return documentsDirectory
        }
    
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
//                                    if f.contains(".txt"){
//                                        // Open file and split lines into an array
//                                        if let lines = try? String(contentsOf: URL(string: "\(uploadHistFilePath)\(f)")!) {
//                                            uploadHistoryFileList.append(contentsOf: lines.components(separatedBy: "\n"))
//                                            //                                        print("Upload History array:")
//                                            //                                        print(uploadHistoryFileList)
//                                            
//                                        }
//                                    }
                                    
                                    // NEW UPLOADED ITEM STRUCT
                                    if f.contains(".json") {
                                        let jsonData = try Data(contentsOf: URL(string: "\(uploadHistFilePath)\(f)")!)
                                        let jsonDecoder = JSONDecoder()
                                        var itemResults = try jsonDecoder.decode([UploadedItem].self, from: jsonData)
                                        
                                        for result in itemResults {
                                            allUploadedFiles.append(
                                                UploadedItem(fileName: result.fileName,
                                                             checksum: result.checksum)
                                            )
                                        }
                                        
                                        itemResults = [UploadedItem]()
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
            // folder error
        }
    }
    
    func getTripAndRouteNames() async {
        
        tripsSubfolders = []
        
        // Run through local folders and make a list of trip and route folder names.
        let fm = FileManager.default
        
        var rootDir: URL? {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            return documentsDirectory
        }
    
        // Get device ID and make path
        let appRootPath = "\(DeviceUUID().deviceUUID)/trips"
        localFilePath = (rootDir?.appendingPathComponent(appRootPath))!

        // Loop through trips
        do {
            let tripPaths = try fm.contentsOfDirectory(atPath: localFilePath!.path)
            
            for trip in tripPaths {
                tripsSubfolders.append(trip)
            }
        } catch {}
    }
    
    // Call PHP to call .py function
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
                print("  🟩 Status code: \(statusCode). Check tables and/or View Captured Points for results.")
                consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  🟩 Status code: \(statusCode). Check tables and/or View Captured Points for results.")
                self.responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
//                print("****** response data = \(self.responseString!)")
                complete = true
                return complete
            } else {
                print("  🟨 Status code: \(statusCode)")
                consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  🟨 Status code: \(statusCode)")
            }
          } catch let error as NSError {
              print("  🟥 Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
              consoleText = tea.appendToTextEditor(oldText: consoleText, newText: "  🟥 Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
          }
                                                                      
        return complete
    }
}
