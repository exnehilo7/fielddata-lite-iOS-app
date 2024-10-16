//
//  ScanPhotosInFolderForText.swift
//  FERN
//
//  Created by Hopp, Dan on 5/14/24.
//
//  Whipped-up view to scan the images within a trip's folder. Currently looks for images within the trip name's folder. Image cycling is not built to handle the new subfolder setup (The "metadata", "scoring", and "upload_history" folders under the trip name folder)
//
//  20-SEP-2024: No need to have the GPS feed running while this view is active.

import SwiftUI
import SwiftData

struct ScanPhotosInFolderForText: View {
    
    var gps: GpsClass
    
    @Environment(\.modelContext) var modelContext // swift data
    @Query var sdTrips: [SDTrip]
    @Query var settings: [Settings]
    
    @State private var image = UIImage()
    @State private var consoleText = ""
    @State private var totalFiles = 0
    @State private var counter = 0 //getImageFileNames is where the starting value is set
    @State private var selectedTrip = ""
    @State private var showAcceptScannedText = false
    @State private var showTripList = true
    @State private var showGetNextPic = true
    
    @State private var scannedText = ""
    
    @State private var fileList: [String] = []
    
    // Text recognition
    @ObservedObject var recognizedContent = RecognizedContent()
    @State private var isRecognizing = false
    
    var body: some View {
        // Show trips. Tap on trip to cycle through photos and save file name and scanned text to a text file under the device ID's folder.
        if showTripList {
            List {
                ForEach(sdTrips) { item in
                    Text(item.name).onTapGesture {
                        selectedTrip = item.name
                        // Create text file if not exists
                        writeScannedTextToFile(tripName: "", uuid: "", scannedText: "")
                        Task {
                            await getImageFileNames(tripName: item.name)
                        }
                        showTripList = false
                    }
                }
            }.onAppear(perform: {gps.stopGPSFeed(settings: settings)})
        }
        if showGetNextPic {
            Button("Get next pic"){
                getNextPic(tripName: selectedTrip)
                showAcceptScannedText = false
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(20)
            .padding(.horizontal)
        }
        Image(uiImage: self.image)
        .resizable()
        .scaledToFit().onTapGesture {
            scanForText(tripName: selectedTrip)
            showAcceptScannedText = true
        }
        if isRecognizing {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor.systemIndigo)))
                .padding(.bottom, 20)
        } else {
            if recognizedContent.items[0].text != ""{
                HStack {
                    Text("Scanned text: ")
                    TextPreviewView(scannedText: recognizedContent.items[0].text)
                }
            }
        }
        Spacer()
        
        if showAcceptScannedText {
            TextField("Tap here to edit scanned text or manually add text.", text: $scannedText).font(.body).padding().onTapGesture {
                        scannedText = recognizedContent.items[0].text
                    }
            Spacer()
            Button("Save scanned text"){
                // Get changes (if any)
//                let textToSave = TextPreviewView(scannedText: recognizedContent.items[0].text).scannedText
                
                // Write to text file
                filterScannedText(tripName: selectedTrip)
            }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(20)
                .padding(.horizontal)
        }
        // Give feedback. Allow user to select text, but don't edit
        TextEditor(text: .constant(self.consoleText))
            .foregroundStyle(.secondary)
            .font(.system(size: 12)).padding(.horizontal)
            .frame(minHeight: 300, maxHeight: 300)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func scanForText(tripName: String) {

            appendToTextEditor(text: "Scanning \(fileList[counter - 1])")
            
            isRecognizing = true
            // Put image in array
            var imageArray = [UIImage]()
            imageArray.append(image)
            
            TextRecognition(scannedImages: imageArray,
                           recognizedContent: recognizedContent) {
                isRecognizing = false }.recognizeText()
        
        
    }
    
    func getImageFileNames(tripName: String) async {
        // Clear vars
        consoleText = ""
        fileList = []
        counter = 0
        
        // FILE LOOP
        let fm = FileManager.default
        
        // Get app's root dir
        var rootDir: URL? {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            return documentsDirectory
        }
        
        var textFilePath: String
        var path: URL
        
        // Get device ID and path
        textFilePath = "\(DeviceUUID().deviceUUID)/trips/\(tripName)"
        path = (rootDir?.appendingPathComponent(textFilePath))!
        
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
        
        appendToTextEditor(text: "Number of files in trip: \(String(totalFiles))")

    }
    
    private func getNextPic(tripName: String){
        // Clear scanned text
        recognizedContent.items[0].text = ""
        scannedText = ""
        
        if totalFiles == 0 {
            appendToTextEditor(text: "No trip selected")
            return
        }
        
        if counter == totalFiles {
            appendToTextEditor(text: "End of trip")
            return
        }
        
        appendToTextEditor(text: "File counter: \(String(counter)). Current image: \(fileList[counter])")
        
        if !fileList[counter].contains(".txt") {
            
            var rootDir: URL? {
                guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
                return documentsDirectory
            }
            var path: URL
            var textFilePath: String
            
            // Get device ID and make path
            textFilePath = "\(DeviceUUID().deviceUUID)/trips/\(tripName)"
            path = (rootDir?.appendingPathComponent(textFilePath))!
 
            let getFile = path.appendingPathComponent(fileList[counter])
            image = UIImage(contentsOfFile: getFile.path)!
        } else {
            appendToTextEditor(text: "No image file")
            image = UIImage()
        }
        counter += 1
        showGetNextPic = false
    }
    
    private func filterScannedText(tripName: String){
        var textToSave = ""
        
        if recognizedContent.items[0].text != "" || scannedText != "" {
            if recognizedContent.items[0].text == scannedText {
                textToSave = recognizedContent.items[0].text
            } else {
                textToSave = scannedText
            }
            textToSave = textToSave.replacingOccurrences(of: ScannedTextPattern().pattern, with: "", options: [.regularExpression])
        } else {
            textToSave = "No text found"
        }
        
        writeScannedTextToFile(tripName: tripName, uuid: fileList[counter - 1], scannedText: textToSave)
        appendToTextEditor(text: "Text \(textToSave) written!")
        
        showAcceptScannedText = false
        showGetNextPic = true
        recognizedContent.items[0].text = ""
    }
    
    // Append info to end of the text file. If the text file doesn't exist, create one.
    private func writeScannedTextToFile(tripName: String, uuid: String, scannedText: String){
        var scannedTextFile: URL? {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            return documentsDirectory
        }
        
        guard let scannedTextFile = scannedTextFile else {
            return
        }

        var filePath: URL
        
        // Make the file name Scanned_Text.txt
        let fileName = "Scanned_Text.txt"
        // Use the unique device ID for the text file name and the folder path.
        let path = scannedTextFile.appendingPathComponent("\(DeviceUUID().deviceUUID)")
        do {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        } catch {}
        filePath = path.appendingPathComponent(fileName)
        
        let message = "\(tripName),\(uuid),\(scannedText)"
        guard let data = (message + "\n").data(using: String.Encoding.utf8) else { return}
    
        if FileManager.default.fileExists(atPath: filePath.path) {
            if uuid.count > 0 {
                if let fileHandle = try? FileHandle(forWritingTo: filePath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            }
        } else {
            if uuid.count < 1 {
                // Create header
                guard let headerData = ("trip_name,pic_uuid,scanned_text\n").data(using: String.Encoding.utf8) else { return}
                try? headerData.write(to: filePath, options: .atomicWrite)
            }
        }
        return
    }
    
    private func appendToTextEditor(text: String){
        self.consoleText.append(contentsOf: "\n" + text)
    }
}
