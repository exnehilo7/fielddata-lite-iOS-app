//
//  SelectAreaView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/5/23.
//
//  This is a menu from a captsone to select a site's area

import SwiftUI
import SwiftData

struct SelectAreaView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    @State private var areaList: [SelectNameModel] = []
    var phpFile: String
    var columnName: String
    
    var body: some View {
        
        VStack {
            HStack{
                Spacer()
                Button ("Refresh"){
                    Task {
                        await qryAreas()
                    }
                }.padding(.trailing, 25)
            }
            NavigationStack {
                List (self.areaList) { (area) in
                    NavigationLink(area.name) {
                        // Pass vars to view
                        SearchByNameView(areaName: area.name, columnName: columnName).navigationTitle(area.name)
                    }
                    .bold()
                }
            }
        // Call PHP POST
        }.task {await qryAreas()}
    }
    
    // IF VIEW IS USED AGAIN, WILL NEED TO USE THE UPDATED ShowListFromDatabaseView
    // Process DML and get reports
    private func qryAreas() async {
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/" + phpFile) else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // pass name of search column to use
        let postString = "_query_name=\(columnName)"
        
        let postData = postString.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: postData!, delegate: nil)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            decoder.dataDecodingStrategy = .deferredToData
            decoder.dateDecodingStrategy = .deferredToDate
            
            
            // convert JSON response into class model as an array
            self.areaList = try decoder.decode([SelectNameModel].self, from: data)
            
            // Debug catching from https://www.hackingwithswift.com/forums/swiftui/decoding-json-data/3024
        } catch DecodingError.keyNotFound(let key, let context) {
            Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
        } catch let error as NSError {
            NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
        } catch {
            areaList = []
        }
    }
}
