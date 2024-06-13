//
//  TestViewColtrollerView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/12/24.
//  A template for MVC. View part.
//  From https://stackoverflow.com/questions/62504435/how-to-call-a-uikit-viewcontroller-method-from-swiftui-view

import SwiftUI

struct TestViewColtrollerView: View {
    @StateObject private var coordinator: BridgingCoordinator

       init() {
           let coordinator = BridgingCoordinator()
           self._coordinator = StateObject(wrappedValue: coordinator)
       }

       var body: some View {
           VStack {
               Text("Swift UI View")
               
               Spacer()
               
               Button(action: buttonTapped) {
                   Text("Call function on UIViewControllerRepresentable VC")
               }
               //.disabled(coordinator.vc == nil)

               UIViewControllerRepresentation(bridgingCoordinator: coordinator)

           }
       }
       private func buttonTapped() {
           coordinator.vc.doSomething()
       }
    
    
}
