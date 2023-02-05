//
//  Functions.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//

import Foundation
import SwiftUI

// To allow a live preview for debugging. From https://developer.apple.com/forums/thread/118589
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    var body: some View {
        content($value)
    }

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(wrappedValue: value)
        self.content = content
    }
}

//func getPhpResponse<T> (model: T.Type, urlString: String) where T : ResponseModel {
//    
//    var emptyModel = [model] = []
//    
//    guard let url: URL = URL(string: urlString) else {
//        Swift.print("invalid URL")
//        return
//    }
//    
//    var urlRequest: URLRequest = URLRequest(url: url)
//    urlRequest.httpMethod = "GET"
//    URLSession.shared.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
//        // check if response is okay
//        
//        guard let data = data else {
//            print("invalid response")
//            return
//        }
//        
//        // convert JSON response into class model as an array
//        do {
//            emptyModel = try JSONDecoder().decode([model], from: data)
//            //                            } catch {
//            //                                print(error.localizedDescription)
//            //                            }
//            //
//            //                            // Try the Observeable objects:
//            //                            do {
//            //                                self.models.plotList = try JSONDecoder().decode([SearchByNameModel].self, from: data)
//        } catch DecodingError.keyNotFound(let key, let context) {
//            Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
//        } catch DecodingError.valueNotFound(let type, let context) {
//            Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
//        } catch DecodingError.typeMismatch(let type, let context) {
//            Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
//        } catch DecodingError.dataCorrupted(let context) {
//            Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
//        } catch let error as NSError {
//            NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
//        }
//        
//    }).resume()
//}
