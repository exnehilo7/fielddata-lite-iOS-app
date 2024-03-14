//
//  CompletedTripView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/2/24.
//
//  19-JAN-2024: Switch to SwiftData
//  14-MAR-2024: When there are ~130 files, sometimes the app will "Terminating app due to uncaught exception 'NSGenericException', reason: '*** Collection <__NSCFSet: 0x300da52f0> was mutated while being enumerated."

import SwiftUI
import SwiftData

struct CompletedTripView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    @Query var sdTrips: [SDTrip]
    
    // From calling view
    var tripName: String
    
    @State var responseString: NSString?
    
    @State var isLoading = false
    
    @State var totalUploaded = 0
    @State var totalFiles = 0

    
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
        Spacer()
        Text("Trip \(tripName) is complete!")
        Text("")
        Text("The images are stored in:")
        Text("Files -> On My [Device] -> FERN ->")
        Text ("[Unique UUID] -> trips -> \(tripName).")
        Spacer()
//        print("ForEach(sdTrips) { item in")
        ForEach(sdTrips) { item in // There probably is a better way to get just one specific trip
            // Focus on the relevant trip
            if (item.name == tripName){
                // If no upload, show button
                if (!item.allFilesUploaded) {
                    VStack{
//                        Text("File \(totalUploaded) of \(totalFiles) uploaded")
                        ProgressView("File \(totalUploaded) of \(totalFiles) uploaded", value: Double(totalUploaded), total: Double(totalFiles))
                        // Hide upload button if in progress
                        if (!isLoading) {
                            Button {
                                Task {
                                    // Funciton to upload files. Upload needs to know where it left off if there was an error? Alert user if no signal; don't initiate upload? (Don't show button if no signal?)
                                     await myFileUploadRequest(tripName: tripName, uploadScriptURL: settings[0].uploadScriptURL, trip: item)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20))
                                    Text("Upload Remaining Trip Files")
                                        .font(.headline)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .padding(.horizontal)
                            }
                        }
                    }
                    // for use elsewhere?
                    //setResponseMsgToBlank()
                } else {Text("Trip uploaded!")}
            }
        }
        Spacer()
    } // end body view
    
    // MARK: Functions
    private func myFileUploadRequest(tripName: String, uploadScriptURL: String, trip: SDTrip) async
    {
//            DispatchQueue.global().async {
        
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
//        var getFile: URL
        var uploadFilePath: String
        
        // Get device ID and make path
        if let deviceUuid = await UIDevice.current.identifierForVendor?.uuidString
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
//            let semaphore = DispatchSemaphore(value: 0)
//            Task {
                
                
                //                    print(super.defaultDirectoryURL().absoluteURL(storePathURL))
                
                // Clear trips
                trip.files?.removeAll()
                
//                semaphore.signal()
//            }
//            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            
                
        // Populate trips
        for item in items {
            // Just the filename
            //                print("\(item)")
            trip.files?.append(TripFile(fileName: item, isUploaded: false))
        }
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print("Directory loop error")
        }
        
        
        // Get file items
        let items = trip.files
        
        // get total number of files
        self.totalFiles = items?.count ?? 0
        
        // Reset counters
//                    self.totalUploaded = 0
        //            uploadProg = 0
        
//        // get total of uploaded
//        for item in items ?? [] {
//            if item.isUploaded {
////                print("\(item.fileName) has already been uploaded!")
//                    self.totalUploaded += 1
//            }
//            else {
////                print("\(item.fileName) will be uploaded")
//            }
//        }
        
        // upload txt file first
        // loop through files in trip array
        for item in items ?? [] {
            if item.fileName.contains(".txt") {
                
                processFile(item: item, uploadFilePath: uploadFilePath,
                             boundary: boundary, request: request,
                             path: path, trip: trip)
            }
        }
        
        // Upload non-txt files
        // loop through files in trip array
        for item in items ?? [] {
            if !item.fileName.contains(".txt") {
                // Ignore if already uploaded
//                if (!item.isUploaded) {
                    
                    processFile(item: item, uploadFilePath: uploadFilePath,
                                 boundary: boundary, request: request,
                                 path: path, trip: trip)
                
//                }
            }
        }
        
        print("💾 Files in trip array loop complete!")
        
        isLoading = false
    }
    
    private func processFile(item: TripFile, uploadFilePath: String,
                             boundary: String, request: NSMutableURLRequest, 
                             path: URL, trip: SDTrip){
        
        //KeyValuePairs
        let paramDict = [
            "firstName"     : "FERN",
            "lastName"      : "Demo",
            "userId"        : "0",
            "fileSavePath"  : "\(uploadFilePath)",
            "fileName"      : "\(item.fileName)"
        ]
        
        // path to save the file:
        let pathAndFile = "\(uploadFilePath)/\(item.fileName)"
        
        // path to get the file:
        let getFile = path.appendingPathComponent(item.fileName)
        
        // Is uploaded?
        if !doesFileExist(item: item, request: request, params: paramDict, trip: trip) {
            // Upload file
            request.httpBody = self.createBodyWithParameters(parameters: paramDict, filePathKey: "file", fileData: NSData(contentsOf: getFile)!, boundary: boundary, uploadFilePath: pathAndFile)
            uploadFile(item: item, request: request, trip: trip)
        }
        
        // myActivityIndicator.startAnimating();
    }
    
    private func doesFileExist(item: TripFile, request: NSMutableURLRequest, params: [String:String], trip: SDTrip) -> Bool {
        
        var exists = false
        
        let httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        
        request.httpBody = httpBody
        
        // Pause the thread until this dataTask completes
//        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request as URLRequest) {(data, response, error)  in
            
            if error != nil {
                print("🔴 error=\(String(describing: error))")
                // signal to continue
//                semaphore.signal()
                return
            }
            
            let statusCode = (response as! HTTPURLResponse).statusCode
                // is 200?
            if statusCode == 200 {
                
                // Get response
                self.responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                // Is success?
                if (self.responseString ?? "nada").contains("file exists!") {
                    print("🟠 \(item.fileName) already exists.")
                    self.totalUploaded += 1
                    exists = true
//                    return
                } else {
                    print("🟡 Status code: \(statusCode)")
                }
            }
            if (totalFiles == totalUploaded) {
                trip.allFilesUploaded = true
                print("🔵 All files uploaded!")
//                    return
            }
            
            // signal to continue
//            semaphore.signal()
        }.resume()
        // Hit pause
//        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return exists
    }
    
    private func uploadFile(item: TripFile, request: NSMutableURLRequest, trip: SDTrip) {
        
        print("🟣 uploadFile is firing!")
        
        // Pause the thread until the upload process completes
        let semaphore = DispatchSemaphore(value: 0)
        // Upload file
        URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                print("🔴 error=\(String(describing: error))")
                // signal the for loop to continue
                semaphore.signal()
                return
            }
            
            // You can print out response object
//            print("******* response = \(String(describing: response))")
            
            print("Uploading \(item.fileName)...")
            
            // Print out reponse body
//            Task { [self] in
//            DispatchQueue.main.async { [self] in // Apparently Task is better than DispatchQueue.main.async? (but we want to sync the uploads; wait until the process completes before moving to the next file in the list.
            let statusCode = (response as! HTTPURLResponse).statusCode
                // is 200?
                if statusCode == 200 {
                   
                    // Get response
                    self.responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
//                    print("****** response data = \(self.responseString!)")
                    // Is success?
                    if (self.responseString ?? "nada").contains("successfully!") {
                        self.totalUploaded += 1
//                        item.isUploaded = true

                        print("🟢 \(item.fileName) is uploaded!")
                        
                        // signal the for loop to continue
//                        semaphore.signal()
                    // File exists?
//                    } else if (self.responseString ?? "nada").contains("file exists!") {
//                        print("🟣 \(item.fileName) already exists.")
//                        self.totalUploaded += 1
//                        // signal the for loop to continue
////                        semaphore.signal()
                    } else {
                        print("🟡 Status code: \(statusCode)")
                        // signal the for loop to continue
    //                    semaphore.signal()
                    }
                // If all files successfully uploaded, set allFilesUploaded to true
                if (totalFiles == totalUploaded) {
                    trip.allFilesUploaded = true
                    print("🔵 All files uploaded!")
//                    return
                }
                // signal the for loop to continue
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
    
}
