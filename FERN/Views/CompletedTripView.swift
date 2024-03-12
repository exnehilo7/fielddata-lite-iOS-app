//
//  CompletedTripView.swift
//  FERN
//
//  Created by Hopp, Dan on 1/2/24.
//
//  19-JAN-2024: Switch to SwiftData

import SwiftUI
import SwiftData

struct CompletedTripView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    @Query var sdTrips: [SDTrip]
    
    // From calling view
    var tripName: String
    
    // Activate UploadImage class
//    @ObservedObject var uploadImage = UploadImage()
    
    @State var responseString: NSString?
//    var isResponseReceived: Bool!
    
//    var fileNameCounter = 0
    @State var isLoading = false
    
    @State var totalUploaded = 0
    @State var totalFiles = 0
    @State var fileSuccess = true
    
    // For progress bar
//    @State private var uploadProg = 0.0
    
    let semaphore = DispatchSemaphore(value: 1)
    
    
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
//    @MainActor
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
        var getFile: URL
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
            
//                    print(super.defaultDirectoryURL().absoluteURL(storePathURL))
            
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
//                DispatchQueue.main.async {
            self.totalFiles = items?.count ?? 0
//                }
        
        // Reset counters
//                DispatchQueue.main.async {
//                    self.totalUploaded = 0
//                }
        //            uploadProg = 0
        
        // get total of uploaded // WHY ISN'T THIS COUNTING?
        for item in items ?? [] {
            if item.isUploaded {
                print("\(item.fileName) has already been uploaded!")
//                        DispatchQueue.main.async {
                    self.totalUploaded += 1
//                        }
            }
            else {
                print("\(item.fileName) will be uploaded")
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
            
//                    if self.isLoading {
//                        self.isLoading = false
            // if isUploaded = false
            if (!item.isUploaded) { // What's up with the isUploaded on swift data?
                
                // path to save the file:
                let pathAndFile = "\(uploadFilePath)/\(item.fileName)"
                
                // path to get the file:
                getFile = path.appendingPathComponent(item.fileName)
                
                request.httpBody = self.createBodyWithParameters(parameters: param, filePathKey: "file", fileData: NSData(contentsOf: getFile)!, boundary: boundary, uploadFilePath: pathAndFile)
                
                // myActivityIndicator.startAnimating();
                
//                let myUrl = NSURL(string: uploadScriptURL)
//                let request = NSMutableURLRequest(url:myUrl! as URL)
//                request.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
//                request.httpMethod = "POST"
                
//                do {
//                    let dataD = dataString.data(using: .utf8)
//                    let (data, response) = try await URLSession.shared.upload(for: request as URLRequest, from: NSData(contentsOf: getFile)! as Data)
                    // How to send a file and POST values vie POST?
                if fileSuccess {
                    uploadFile(item: item, request: request, trip: trip) // Upload process in a function using the "old" completion handler
                }
                    // May be useful later?
//                    let statusCode = (response as! HTTPURLResponse).statusCode
//                        if statusCode == 200 {
//                            print("SUCCESS")
//                        } else {
//                            print("FAILURE")
//                        }
                    
//                } catch let error as NSError {
//                    NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
//                }
                
            } // end if
//                    } // end isLoading
        } // end for
//            } // end dispach global async
        print("files in trip array loop complete!")
        
        isLoading = false
    }
    
//    @MainActor
    private func uploadFile(item: TripFile, request: NSMutableURLRequest, trip: SDTrip) {
        
//        if isLoading { return }
//        isLoading = true
        fileSuccess = false
        
        let semaphore = DispatchSemaphore(value: 0)
        
//        URLSession.shared.dataTask(with: request as URLRequest) {
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            data, response, error in
            
            if error != nil {
                print("error=\(String(describing: error))")
                return
            }
            
            // You can print out response object
//            print("******* response = \(String(describing: response))")
            
            print("Uploading \(item.fileName)")
            
            // Print out reponse body
//            Task { [self] in
//            DispatchQueue.main.async { [self] in // Apparently Task is better than DispatchQueue.main.async? (but we want to sync the uploads; wait until the process completes before moving to the next file in the list.
                self.responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("****** response data = \(self.responseString!)")
                if (self.responseString ?? "nada").contains("successfully!") {
//                    DispatchQueue.main.async {
                        self.totalUploaded += 1
//                    }
                    item.isUploaded = true
                    fileSuccess = true
                    print("\(item.fileName) is uploaded!")
                    
                    // call func again?
                    // uploadFile(item: item, request: request, trip: trip)
                    
                    
                    // If all files successfully uploaded, set allFilesUploaded to true
                    if (totalFiles == totalUploaded) {
                        trip.allFilesUploaded = true
                        print("All files uploaded!")
                        return
                    }
//                }
                
//                isLoading = false
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
        })//.resume()
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
//        return fileSuccess
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
