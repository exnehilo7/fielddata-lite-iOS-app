//
//  CapstoneModels.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.
//

import Foundation


// Model object for SelectAreaView.
class SelectNameModel: Codable, Identifiable {
    var name = ""
}

// Model for SelectNoteView
struct SelectNoteModel: Codable, Identifiable, Hashable {
    var id = ""
    var note = ""
    var confirmDelete = false
    
    enum CodingKeys: CodingKey {
        case id, note
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(note, forKey: .note)
    }
    
    init() { }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        note = try container.decode(String.self, forKey: .note)
    }
}
