//
//  StartScreenView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/9/23.
//
// Splash screen help from https://mobiraft.com/ios/swiftui/how-to-add-splash-screen-in-swiftui/

import SwiftUI

struct StartScreenView: View {
        
    @State private var active: Bool = false
    
    var body: some View {
        // Toggle splash screen and Main Menu View
        if active {
            MainMenuView()
        }
        else {
            VStack {
                VStack { // Title
                    HStack { // F
                        Text("F").font(.system(size: 100)).foregroundColor(.green)
                        Text("ield").padding(.leading, -8).padding(.top, 20).font(.system(size: 70))
                        Spacer()
                    }
                    HStack { // E
                        Text("E").font(.system(size: 100)).foregroundColor(.green)
                        Text("xpedition").padding(.leading, -8).padding(.top, 20).font(.system(size: 70))
                        Spacer()
                    }.padding(.top, -70)
                    HStack { // R
                        Text("R").font(.system(size: 100)).foregroundColor(.green)
                        Text("routing and").padding(.leading, -8).padding(.top, 20).font(.system(size: 70))
                        Spacer()
                    }.padding(.top, -70)
                    HStack { // N
                        Text("N").font(.system(size: 100)).foregroundColor(.green)
                        Text("avigation").padding(.leading, -8).padding(.top, 20).font(.system(size: 70))
                        Spacer()
                    }.padding(.top, -70)
                }.padding(.leading, 50).padding(.top, 4)
                Spacer()
                
                Button {
                    
                } label: {
                    Image(systemName: "leaf.circle.fill").bold(false).foregroundColor(.green).font(.system(size: 450))
                }
                Spacer()
                
            }.onAppear {
                // Set timer for splashscreen fadeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        active = true
                    }
                }
            }
        }// end else
    }
}

struct StartScreenView_Previews: PreviewProvider {
    static var previews: some View {
        StartScreenView()
    }
}
