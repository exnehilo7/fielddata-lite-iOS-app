//
//  FERNApp.swift
//  FERN
//
//  Created by Hopp, Dan on 2/1/23.
//

import SwiftUI

@main //SearchByNameView?
struct FERNApp: App {
    
//    @StateObject var wtf : MapAnnotationItem_Container
//    
//    init() {
//        _wtf = StateObject(wrappedValue: MapAnnotationItem_Container())
//    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                StartScreenView()
           }
        }
    }
}
