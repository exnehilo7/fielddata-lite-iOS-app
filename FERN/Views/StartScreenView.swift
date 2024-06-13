//
//  StartScreenView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/9/23.
//
// Splash screen help from https://mobiraft.com/ios/swiftui/how-to-add-splash-screen-in-swiftui/

import SwiftUI
//import SwiftData

struct StartScreenView: View {
    
    // Bridging coordinator
    @StateObject private var bridgingCoordinator: StartScreenBridgingCoordinator
    
    @State private var active: Bool = false
    
    init() {
        let startScreenCoordinator = StartScreenBridgingCoordinator()
        self._bridgingCoordinator = StateObject(wrappedValue: startScreenCoordinator)
    }
    
//    @Environment(\.modelContext) var modelContext
//    @Query var settings: [Settings]
    
    var body: some View {
        // Toggle splash screen and Main Menu View. After XCode update, no longer working?
        if active {
            TestViewColtrollerView()
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
            }.onAppear {
                
//                // Create settings if none exist
//                if settings.count < 1 {
//                    modelContext.insert(Settings())
//                }
                
                bridgingCoordinator.startScreenViewController.viewDidLoad()
                
                // Set timer for splashscreen fadeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        active = true
                    }
                }
            }.fullScreenCover(isPresented: $active) {
                TestViewColtrollerView()
            }
        }// end else
    }
}

//struct StartScreenView_Previews: PreviewProvider {
//    static var previews: some View {
//        StartScreenView()
//    }
//}
