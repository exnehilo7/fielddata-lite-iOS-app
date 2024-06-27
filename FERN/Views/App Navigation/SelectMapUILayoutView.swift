//
//  SelectMapUILayoutView.swift
//  FERN
//
//  Created by Hopp, Dan on 6/24/24.
//
//  Sets the layout on MapView

import SwiftUI

struct SelectMapUILayoutView: View {
    
    var map: MapClass
    var gps: GpsClass
    var camera: CameraClass
    var mapMode: String
    var tripOrRouteName: String
    var columnName: String
    var organismName: String
    var queryName: String
    
    var body: some View {
        NavigationStack{
            List {
                NavigationLink {
                    MapView(map: map, gps: gps, camera: camera, mapMode: mapMode, tripOrRouteName: tripOrRouteName, columnName: columnName, organismName: organismName, queryName: queryName, mapUILayout: "standard")
                        .navigationTitle(tripOrRouteName).font(.subheadline)
                } label: {
                    HStack {
                        Image(systemName: "s.circle.fill").bold(false).foregroundColor(.gray)
                        Text("Standard")
                    }
                }
                NavigationLink {
                    MapView(map: map, gps: gps, camera: camera, mapMode: mapMode, tripOrRouteName: tripOrRouteName, columnName: columnName, organismName: organismName, queryName: queryName, mapUILayout: "scoring")
                        .navigationTitle(tripOrRouteName).font(.subheadline)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle").bold(false).foregroundColor(.gray)
                        Text("Scoring")
                    }
                }
            }
        }
        .onAppear(perform: {
            // Reset previously snapped pic if view was swiped down before image was saved
            camera.clearCustomData()
            camera.resetCamera()
            
            // Need to reset vars in MapModel
            map.resetMapModelVariables()
        })
    }
}
