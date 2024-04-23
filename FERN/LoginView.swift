//
//  LoginView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//

import SwiftUI

struct LoginView: View {
    
    @State var userName: String
    @State var password: String
    
    var body: some View {
        List {
            Text("Login")
            
            Section("User Name") {
                TextField("tbd", text: $userName)
            }
            Section("Password") {
                TextField("tbd", text: $password)
            }
            
            Section("Dev Access to App") {
                NavigationLink("Main Menu") {
                    MainMenuView()
                        .navigationTitle("FERN")
                }
                
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(false) { _ in LoginView(userName: "previewProvider", password: "password") }
    }
}
