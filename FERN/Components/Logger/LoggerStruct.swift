//
//  LoggerStruct.swift
//  FERN
//
//  Created by Hopp, Dan on 10/7/24.
//
//  Code from https://stackoverflow.com/questions/44537133/how-to-write-application-logs-to-file-and-get-them
//  Usage example: print(#function,"string1", "optional string N", to: &logger)

import Foundation

struct Log: TextOutputStream {

    func write(_ string: String) {
        let fm = FileManager.default
        let log = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("log.txt")
        if let handle = try? FileHandle(forWritingTo: log) {
            handle.seekToEndOfFile()
            handle.write(string.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? string.data(using: .utf8)?.write(to: log)
        }
    }
}

var logger = Log()
