//
//  SelectMapPlatformView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/29/24.
//

import SwiftUI

struct SelectMapPlatformView: View {
    
    @EnvironmentObject var menuListBridgingCoordinator: MenuListBridgingCoordinator
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    var mapMode: String
    var columnName: String
    var organismName: String
    var queryName: String
    
    var body: some View {
        
        VStack {
            NavigationStack {
                List {
                    NavigationLink {
                        ShowListFromDatabaseView(map: map, gps: gps, camera: camera, mapMode: mapMode, columnName: columnName, organismName: organismName, queryName: queryName)
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
