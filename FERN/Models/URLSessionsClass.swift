//
//  URLSessionsClass.swift
//  FERN
//
//  Created by Hopp, Dan on 6/18/24.
//

import Foundation


// Get data using POST
class URLSessionUpload {
    func urlSessionUpload (request: URLRequest, postData: Data) async throws -> Data {
        let (data, _) = try await URLSession.shared.upload(for: request, from: postData, delegate: nil)
        return data
    }
}

// Get data, no POST
class URLSessionData {
    func urlSessionData (url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}

// Call a URL POST session with no data return
class URLSessionUploadNoReturn {
    func urlSessionUploadNoReturn (request: URLRequest, postData: Data) async throws {
        let (_, _) = try await URLSession.shared.upload(for: request, from: postData, delegate: nil)
    }
}
