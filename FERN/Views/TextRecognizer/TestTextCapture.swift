//
//  TestTextCapture.swift
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

struct TestTextCapture: View {
    
    @ObservedObject var recognizedContent = RecognizedContent()
    @State private var showScanner = false
    @State private var isRecognizing = false
   
    var body: some View {
       NavigationView {
           ZStack(alignment: .bottom) {
               List(recognizedContent.items, id: \.id) { textItem in
                   NavigationLink(destination: TextPreviewView(text: textItem.text)) {
                       Text(String(textItem.text.prefix(50)))//.appending("..."))
                   }
               }
               
               
               if isRecognizing {
                   ProgressView()
                       .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor.systemIndigo)))
                       .padding(.bottom, 20)
               }
               
           }
           .navigationTitle("Text Scanner")
           .navigationBarItems(trailing: Button(action: {
               guard !isRecognizing else { return }
               showScanner = true
           }, label: {
               HStack {
                   Image(systemName: "doc.text.viewfinder")
                       .renderingMode(.template)
                       .foregroundColor(.white)
                   
                   Text("Scan")
                       .foregroundColor(.white)
               }
               .padding(.horizontal, 16)
               .frame(height: 36)
               .background(Color(UIColor.systemIndigo))
               .cornerRadius(18)
           }))
       }
       .sheet(isPresented: $showScanner, content: {
           ScannerView { result in
               switch result {
                   case .success(let scannedImages):
                       isRecognizing = true
                       
                       TextRecognition(scannedImages: scannedImages,
                                       recognizedContent: recognizedContent) {
                           // Text recognition is finished, hide the progress indicator.
                           isRecognizing = false
                       }
                       .recognizeText()
                       
                   case .failure(let error):
                       print(error.localizedDescription)
               }
               
               showScanner = false
               
           } didCancelScanning: {
               // Dismiss the scanner controller and the sheet.
               showScanner = false
           }
       })
    }
}
