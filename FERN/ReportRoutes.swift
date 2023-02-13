//
//  ReportRoutes.swift
//  FERN
//
//  Created by Hopp, Dan on 2/13/23.
//

import SwiftUI

// For test table
struct User: Identifiable {
    let id: Int
    var name: String
    var score: Int
}

struct ReportRoutes: View {
    @State private var users = [
        User(id: 1, name: "Buddy", score: 80),
        User(id: 2, name: "Ollie", score: 97),
        User(id: 3, name: "Phee", score: 95)
    ]
    
    var body: some View {
        Table(users) {
            TableColumn("Name", value: \.name)
            TableColumn("Score") { user in
                Text(String(user.score))
            }
        }
    }
}

struct ReportRoutes_Previews: PreviewProvider {
    static var previews: some View {
        ReportRoutes()
    }
}
