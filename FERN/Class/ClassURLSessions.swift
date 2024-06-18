//
//  ClassURLSessions.swift
//  FERN
//
//  Created by Hopp, Dan on 6/18/24.
//

import Foundation

// Test global function
class URLSessionUpload {
    // Get data using POST
    func urlSessionUpload (request: URLRequest, postData: Data) async throws -> Data {
        let (data, _) = try await URLSession.shared.upload(for: request, from: postData, delegate: nil)
        return data
    }
}

class URLSessionData {
    // Get data, no POST
    func urlSessionData (url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}

class URLSessionUploadNoReturn {
    // Call a URL POST session with no data return
    func urlSessionUploadNoReturn (request: URLRequest, postData: Data) async throws {
        let (_, _) = try await URLSession.shared.upload(for: request, from: postData, delegate: nil)
    }
}
