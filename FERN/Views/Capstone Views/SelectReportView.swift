//
//  SelectReportView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/13/23.
//
//  This is a menu from a capstone project to select a report.

import SwiftUI
import SwiftData

struct SelectReportView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    @State private var reportList: [SelectNameClass] = []
    var phpFile: String
    
    var body: some View {
        
        // List the reports
        VStack {
            HStack{
                Spacer()
                Button ("Refresh"){
                    Task {
                        await qryReports()
                    }
                }.padding(.trailing, 25)
            }
            NavigationStack {
                List (self.reportList) { (area) in
                    NavigationLink(area.name) {
                        ReportRoutes(phpFile: "menusAndReports.php").navigationTitle(area.name + " as of: " + Date.now.formatted(date: .long, time: .shortened))
                    }
                    .bold()
                }
            }
        }.task { await qryReports()}
    }
    
    // Process DML and get reports
    private func qryReports() async {
        
        guard let url: URL = URL(string: settings[0].databaseURL + "/php/" + phpFile) else {
            Swift.print("invalid URL")
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "_query_name=report_view"
        
        let postData = postString.data(using: .utf8)
            
            do {
                let (data, _) = try await URLSession.shared.upload(for: request, from: postData!, delegate: nil)
                
                // Necessary?
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dataDecodingStrategy = .deferredToData
                decoder.dateDecodingStrategy = .deferredToDate
                
                
                // convert JSON response into class model as an array
                self.reportList = try decoder.decode([SelectNameClass].self, from: data)
                
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
                reportList = []
            }
    }
}
