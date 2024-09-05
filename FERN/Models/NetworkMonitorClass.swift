//
//  NetworkMonitorClass.swift
//  FERN
//
//  Created by Hopp, Dan on 8/1/24.
//
// Code help from https://www.hackingwithswift.com/plus/networking/user-friendly-network-access

import Foundation
import Network

class NetworkMonitorClass: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Monitor")
    
    /* See whether it’s active (do we have access to the network?), whether it’s expensive (cellular or WiFi using a cellular hotspot), whether it’s constrained (restricted by low data mode), and the exact connection type we have (WiFi, cellular, etc)
     */
    var isActive = false
    var isExpensive = false
    var isConstrained = false
    var connectionType = NWInterface.InterfaceType.other
    
    init() {
        monitor.pathUpdateHandler = { path in
            // Store our latest networking values in our property.
            self.isActive = path.status == .satisfied
            self.isExpensive = path.isExpensive
            self.isConstrained = path.isConstrained

            // Make an array of all possible connection types then find the first one that is actually available.
            let connectionTypes: [NWInterface.InterfaceType] = [.cellular, .wifi, .wiredEthernet]
            self.connectionType = connectionTypes.first(where: path.usesInterfaceType) ?? .other

            // Then notify anyone who is watching for updates.
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }

        monitor.start(queue: queue)
    }
}
