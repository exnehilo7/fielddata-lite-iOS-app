//
//  SelectMapPlatformView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/29/24.
//

import SwiftUI

struct SelectMapPlatformView: View {
    
//    @EnvironmentObject var menuListBridgingCoordinator: MenuListBridgingCoordinator
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    var upload: FileUploadClass
    var mapMode: String
    var columnName: String
    var organismName: String
    var mapQuery: String
    var measurements: MeasurementsClass
    var offlineMode: Bool
    
    var body: some View {
        
        VStack {
            NavigationStack {
                List {
                    NavigationLink {
                        SelectTripTypeView(map: map, gps: gps, camera: camera, upload: upload, mapMode: mapMode, columnName: columnName, organismName: organismName, mapQuery: mapQuery, measurements: measurements, offlineMode: offlineMode)
//                            .environmentObject(menuListBridgingCoordinator)
                            .navigationTitle("Select Trip Type")
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse").bold(false).foregroundColor(.gray)
                            Text("Apple Map")
                        }
                    }
                    NavigationLink {
                        SelectTripForCesiumView()
//                            .environmentObject(menuListBridgingCoordinator)
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
