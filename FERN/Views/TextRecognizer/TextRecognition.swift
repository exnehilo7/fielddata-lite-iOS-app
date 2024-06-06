//
//  TextRecognition.swift
//  FERN
//
//  Created by Hopp, Dan on 4/4/24.
//
/*
 MIT License

 Copyright (c) 2021 Simon Ng

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 */

import SwiftUI
import Vision

struct TextRecognition {
    // For Camera View testing, try single image
    var scannedImages: [UIImage]
//    var scannedImages: UIImage
    @ObservedObject var recognizedContent: RecognizedContent
    var didFinishRecognition: () -> Void
    
    
    func recognizeText() {
        let queue = DispatchQueue(label: "textRecognitionQueue", qos: .userInitiated)
        queue.async {
            for image in scannedImages {
                guard let cgImage = image.cgImage else { return }
                
                let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    let textItem = ScannedTextItem()
                    try requestHandler.perform([getTextRecognitionRequest(with: textItem)])
                    
                    DispatchQueue.main.async {
                        recognizedContent.items[0].text = textItem.text
                    }
                } catch {
                    print(error.localizedDescription)
                }
                
                DispatchQueue.main.async {
                    didFinishRecognition()
                }
            }
        }
    }
    
    
    private func getTextRecognitionRequest(with textItem: ScannedTextItem) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            observations.forEach { observation in
                guard let recognizedText = observation.topCandidates(1).first else { return }
                textItem.text += recognizedText.string
//                textItem.text += "\n"
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        return request
    }
}
