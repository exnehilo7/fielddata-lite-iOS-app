//
//  QCSelectMapTypeView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/29/24.
//

import SwiftUI

struct QCSelectMapTypeView: View {
    
    @EnvironmentObject var menuListBridgingCoordinator: MenuListBridgingCoordinator
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    
    var body: some View {
        
        VStack {
            NavigationStack {
                List {
                    NavigationLink {
                        SelectTripForAppleMapView(map: map, gps: gps, camera: camera)
                            .environmentObject(menuListBridgingCoordinator)
                            .navigationTitle("Apple Map")
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse").bold(false).foregroundColor(.gray)
                            Text("Apple Map")
                        }
                    }
                    NavigationLink {
                        SelectTripForCesiumView()
                            .environmentObject(menuListBridgingCoordinator)
                            .navigationTitle("Cesium JS")
                    } label: {
                        HStack {
                            Image(systemName: "globe").bold(false).foregroundColor(.gray)
                            Text("Cesium JS")
                        }
                    }
                }
            }
        }
    }
}
