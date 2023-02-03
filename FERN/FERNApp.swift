//
//  FERNApp.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.
//

import SwiftUI

@main
struct FERNApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                LoginView(userName: "Wonder Woman", password: "402436").navigationTitle("Login")
           }
        }
    }
}
