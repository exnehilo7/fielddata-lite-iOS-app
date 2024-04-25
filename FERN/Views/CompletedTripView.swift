//
//  CompletedTripView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/2/24.
//
//  19-JAN-2024: Switch to SwiftData
//  15-MAR-2024: Add checksum. Change array of model objects to array of strings.

import SwiftUI
import SwiftData
import CryptoKit

struct CompletedTripView: View {
    
    @Environment(\.modelContext) var modelContext
//    @Query var settings: [Settings]
    @Query var sdTrips: [SDTrip]
    
    // From calling view
    var tripName: String
    var uploadURL: String
    var cesiumURL: String
    
    @State var responseString: NSString?
    
    @State var isLoading = false
    @State var allFilesProcessed = false
    
    @State var totalUploaded = 0
    @State var totalFiles = 0
    @State var totalProcessed = 0

    @State var consoleText = ""
    
    @State private var showCesiumAndContinueAlert = false
    @State private var continueImageUpload = false
    
    // MARK: Views
    // Get a message from Upload Image
    var responseMessage: some View {
        VStack {
            Text("PHP Response: \(responseString ?? "None")")
        }.font(.system(size: 20))
            .padding()
    }
    
    
    // MARK: Main body
    
    var body: some View {
        ForEach(sdTrips) { item in // There probably is a better way to get just one specific trip
            // Focus on the relevant trip
            if (item.name == tripName){
                VStack {
                    Spacer()
                    Text("Trip \(tripName) is complete!")
                    Text("")
                    VStack {
                        Text("The images are stored in:")
                        Text("Files -> On My [Device] -> FERN ->")
                        Text ("UUID -> trips -> \(tripName).")
                    }.font(.system(size: 15))
                    Spacer()
                    // If all files not processed & uploaded, show button and bar
                    if (!allFilesProcessed || !item.allFilesUploaded) {
//                        VStack{
                            // If all files not uploaded, show bar
                            if (!item.allFilesUploaded){
                                ProgressView("File \(totalUploaded) of \(totalFiles) uploaded", value: Double(totalUploaded), total: Double(totalFiles))
                            }
                            // Hide upload button if in progress
                            if (!isLoading) {
                                Button {
                                    Task {
                                        // Set counters
                                        resetVars()
                                        await beginFileUpload(tripName: tripName, trip: item)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 20))
                                        Text("Upload Trip Files")
                                            .font(.headline)
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .padding(.horizontal)
                                // Give user option to view trip in Cesium and/or continue with iage uploads
                                }.alert("Continue with image upload?", isPresented: $showCesiumAndContinueAlert) {
                                    Link("View trip in CesiumJS", destination: URL(string: cesiumURL + "?jarvisCommand='jarvis show me \(tripName) trip'")!)
                                    Button("OK", action: {
                                        continueImageUpload = true
                                        Task {
                                            // Need to fix upload progress bar counter. There should already be a count of 1.
                                            await beginFileUpload(tripName: tripName, trip: item)
                                        }
                                    })
                                    Button("Cancel", role: .cancel){isLoading = false}
                                } message: {
                                    HStack {
//                                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                                        Text("It is strongly recommended to be connected to a power cable and Wi-Fi when uploading images.")
                                        Text("NOTE: The app cannot yet run in the background or when the device is locked.")
//                                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                                    }
                                }
                            }
//                        }
                        // for use elsewhere?
                        //setResponseMsgToBlank()
                    } else {Text("✅ Files uploaded! ✅")}
                    Spacer()
                    // Give feedback. Allow user to select text, but don't edit
                    TextEditor(text: .constant(self.consoleText))
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12)).padding(.horizontal)
                        .frame(minHeight: 300)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    } // end body view
    
    // MARK: Functions
    private func resetVars(){
        consoleText = ""
        totalUploaded = 0
        totalFiles = 0
        totalProcessed = 0
    }
    
    private func beginFileUpload(tripName: String, trip: SDTrip) async {
        // Show bar
        trip.allFilesUploaded = false
        // Funciton to upload files. Upload needs to know where it left off if there was an error? Alert user if no signal; don't initiate upload? (Don't show button if no signal?)
        await myFileUploadRequest(tripName: tripName, uploadScriptURL: uploadURL, trip: trip)
    }
    
    private func myFileUploadRequest(tripName: String, uploadScriptURL: String, trip: SDTrip) async
    {
        
        // Set var
        isLoading = true

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
        var uploadFilePath: String
        
        var fileList: [String] = []
        
        // Get device ID and make path
        if let deviceUuid = await UIDevice.current.identifierForVendor?.uuidString
        {
            uploadFilePath = "\(deviceUuid)/trips/\(tripName)"
            path = (rootDir?.appendingPathComponent(uploadFilePath))!
        } else {
            uploadFilePath = "no_device_uuid/trips/\(tripName)"
            path = (rootDir?.appendingPathComponent(uploadFilePath))!
        }
        
        // Get a list of all trip files: loop through filenames
        do {
            let items = try fm.contentsOfDirectory(atPath: path.path)
            
            // Populate array with filenames
            for item in items {
                fileList.append(item)
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print("Directory loop error")
        }
        
        // get total number of files
        self.totalFiles = fileList.count
        
        if !continueImageUpload {
            // upload txt file first
            // loop through files in trip array
            for item in fileList {
                if item.contains(".txt") {
                    await processFile(item: item, uploadFilePath: uploadFilePath,
                                      boundary: boundary, request: request,
                                      path: path, trip: trip)
                    
                    // Insert data into DB
                    // If all files are uploaded, insert trip into DB
                    //                if trip.allFilesUploaded == true {
                    if await !insertIntoDatabase(){
                        print("🔵 Database insert complete. Check the database for results.")
                        appendToTextEditor(text: "🔵 Database insert complete. Check the database for results.")
                    }
                    //                }
                    
                    // Give user option to look at webpage or to continue with picture uploads
                    showCesiumAndContinueAlert = true
                    
                }
            }
        }
        
        // Upload non-txt files
        // loop through files in trip array
        if continueImageUpload {
            for item in fileList {
                if !item.contains(".txt") {
                    await processFile(item: item, uploadFilePath: uploadFilePath,
                                      boundary: boundary, request: request,
                                      path: path, trip: trip)
                }
            }
            print("ℹ️ Trip file array loop complete.")
            appendToTextEditor(text: "ℹ️ Trip file array loop complete.")
            continueImageUpload = false
        }
        
        isLoading = false
    }
    
    private func processFile(item: String, uploadFilePath: String,
                             boundary: String, request: NSMutableURLRequest,
                             path: URL, trip: SDTrip) async {
        
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
        
        // Is uploaded?
        if await !doesFileExist(fileName: item, params: paramDict, trip: trip, semaphore: semaphore) {
            // Calculate checksum iOS-side
            let hashed = SHA256.hash(data: NSData(contentsOf: getFile)!)
            let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
//            print("#️⃣ iOS SHA256: \(hashString)")
            
            // Append hash to params
            let mergeDict = paramDict.merging(["sourceHash":"\(hashString)"]) { (_, new) in new }
            
            // Upload file
            request.httpBody = self.createBodyWithParameters(parameters: mergeDict, filePathKey: "file",
                                                             fileData: NSData(contentsOf: getFile)!,
                                                             boundary: boundary, uploadFilePath: pathAndFile)
            uploadFile(fileName: item, request: request, trip: trip, semaphore: semaphore)
        }
        
        // myActivityIndicator.startAnimating();
    }
    
    private func doesFileExist(fileName: String, params: [String:String],
                               trip: SDTrip, semaphore: DispatchSemaphore) async -> Bool {
        
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
                
                finalizeResults(trip: trip)
                
            } else {
                print("🟡 Status code: \(statusCode)")
                appendToTextEditor(text: "🟡 Status code: \(statusCode)")
            }
        } catch let error as NSError {
            NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
        }
        
        return exists
    }
    
    private func uploadFile(fileName: String, request: NSMutableURLRequest, trip: SDTrip, semaphore: DispatchSemaphore) {
        
        print("Uploading \(fileName)...")
        
        // Upload file
        URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                print("🔴 error=\(String(describing: error))")
                appendToTextEditor(text: "🔴 error=\(String(describing: error))")
                // signal the for loop to continue
                semaphore.signal()
                return
            }
            
            // You can print out response object
//            print("******* response = \(String(describing: response))")
            
            // Print out reponse body
            let statusCode = (response as! HTTPURLResponse).statusCode
                // is 200?
                if statusCode == 200 {
                   
                    // Get response
                    self.responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
//                    print("****** response data = \(self.responseString!)")
                    // Is success?
                    if (self.responseString ?? "No response string").contains("successfully!") {
                        upProcessedAndUploadedByOne()
                        print("🟢 \(fileName) is uploaded!")
                        appendToTextEditor(text: "🟢 \(fileName) is uploaded!")
                    }
                    
                    // Checksum failed?
                    else if (self.responseString ?? "No response string").contains("Hashes do not match!") {
                        self.totalProcessed += 1
                        print("🔴 Hashes do not match for \(fileName)!")
                        appendToTextEditor(text: "🔴 Hashes do not match for \(fileName)!")
                    }
                    
                    finalizeResults(trip: trip)
                    
                    // signal the for loop to continue
                    semaphore.signal()
            } else {
                print("🟡 Status code: \(statusCode)")
                appendToTextEditor(text: "🟡 Status code: \(statusCode)")
                semaphore.signal()
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
        }.resume()
        // Hit pause
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
    
    private func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, fileData: NSData, boundary: String, uploadFilePath: String) -> Data {
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
    
    
    private func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    private func setResponseMsgToBlank() {
            DispatchQueue.main.async { [self] in
                self.responseString = "None"
            }
    }
    
    private func upProcessedAndUploadedByOne(){
        self.totalProcessed += 1
        self.totalUploaded += 1
    }
    
    private func finalizeResults(trip: SDTrip){
        // If all files uploaded, set allFilesUploaded = true
        if (totalFiles == totalUploaded) {
            trip.allFilesUploaded = true
            print("🔵 All files uploaded.")
            appendToTextEditor(text: "🔵 All files uploaded.")
        }
        // If all files processed, set allFilesProcessed = true
        if (totalFiles == totalProcessed) {
            self.allFilesProcessed = true
        }
    }
    
    private func appendToTextEditor(text: String){
        self.consoleText.append(contentsOf: "\n" + text)
    }
    
    
    
    private func insertIntoDatabase() async -> Bool {
   
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
//            semaphore.signal()
          } catch let error as NSError {
              NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
          }
                                                                      
        return complete
        
    }
    
}
