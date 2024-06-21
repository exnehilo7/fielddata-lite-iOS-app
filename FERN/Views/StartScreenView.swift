//
//  StartScreenView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/9/23.
//
// Splash screen help from https://mobiraft.com/ios/swiftui/how-to-add-splash-screen-in-swiftui/

import SwiftUI
import SwiftData

struct StartScreenView: View {
    
    // Bridging coordinator
    @State private var bridgingCoordinator: StartScreenBridgingCoordinator
    
    @State private var active: Bool = false
    
    init() {
        let startScreenCoordinator = StartScreenBridgingCoordinator()
        self._bridgingCoordinator = State(wrappedValue: startScreenCoordinator)
    }
    
    @Environment(\.modelContext) var modelContext
    @Query var settings: [Settings]
    
    var body: some View {
        // Toggle splash screen and Main Menu View. (After XCode 15 update, no longer working?)
        if active {
            MainMenuView()
        }
        else {
            VStack {
                VStack { // Title
                    HStack { // F
                        Text("F").font(.system(size: 70)).foregroundColor(.green)
                        Text("ield").padding(.leading, -8).padding(.top, 20).font(.system(size: 40))
                        Spacer()
                    }
                    HStack { // E
                        Text("E").font(.system(size: 70)).foregroundColor(.green)
                        Text("xpedition").padding(.leading, -8).padding(.top, 20).font(.system(size: 40))
                        Spacer()
                    }.padding(.top, -70)
                    HStack { // R
                        Text("R").font(.system(size: 70)).foregroundColor(.green)
                        Text("routing and").padding(.leading, -8).padding(.top, 20).font(.system(size: 40))
                        Spacer()
                    }.padding(.top, -70)
                    HStack { // N
                        Text("N").font(.system(size: 70)).foregroundColor(.green)
                        Text("avigation").padding(.leading, -8).padding(.top, 20).font(.system(size: 40))
                        Spacer()
                    }.padding(.top, -70)
                }.padding(.leading, 50).padding(.top, 4).dynamicTypeSize(...DynamicTypeSize.xxLarge)
                Spacer()
                    Button {
                    } label: {
                        Image(systemName: "leaf.circle.fill").bold(false).foregroundColor(.green).font(.system(size: 300)).dynamicTypeSize(...DynamicTypeSize.xxLarge)
                    }
                Spacer()
                
                StartScreenViewControllerRepresentable(startScreenBridgingCoordinator: bridgingCoordinator)
                
            }.onAppear {
                
                bridgingCoordinator.startScreenViewController.createSettings(settings: settings, modelContext: modelContext)
                
                // Set timer for splashscreen fadeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        active = bridgingCoordinator.startScreenViewController.active ?? true
                    }
                }
            }.fullScreenCover(isPresented: $active) {
                MainMenuView()
            }
        }
    }
}
