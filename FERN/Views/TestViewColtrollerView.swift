//
//  TestViewColtrollerView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/12/24.
//

import SwiftUI

struct TestViewColtrollerView: View {
    @StateObject private var coordinator: BridgingCoordinator
    @StateObject private var nmea: nmeaBridge

       init() {
           let coordinator = BridgingCoordinator()
           self._coordinator = StateObject(wrappedValue: coordinator)
           let nmea = nmeaBridge()
           self._nmea = StateObject(wrappedValue: nmea)
       }

       var body: some View {
           VStack {
               Text("Swift UI View")
               
               Spacer()
               
               Button(action: buttonTapped) {
                   Text("Call function on UIViewControllerRepresentable VC")
               }
               //.disabled(coordinator.vc == nil)
               Spacer()
               Button(action: startNMEA) {
                   Text("Start NMEA")
               }
               Spacer()
               UIViewControllerRepresentation(bridgingCoordinator: coordinator)
               if 1 == 1 {
                   nmeaControllerRepresentation(chikin: nmea)
               }
           }
       }
       
       private func buttonTapped() {
           coordinator.vc.doSomething()
       }
    
        private func startNMEA() {
            nmea.vc.viewDidLoad()
        }
    
    
}
