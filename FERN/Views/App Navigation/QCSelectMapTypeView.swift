//
//  QCSelectMapTypeView.swift
//  FERN
//
//  Created by Hopp, Dan on 5/29/24.
//

import SwiftUI

struct QCSelectMapTypeView: View {
    var body: some View {
        
        VStack {
            NavigationStack {
                List {
                    NavigationLink {
                        SelectTripForAppleMapView()
                            .navigationTitle("Apple Map")//.environmentObject(nmea)
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse").bold(false).foregroundColor(.gray)
                            Text("Apple Map")
                        }
                    }
                    NavigationLink {
                        SelectTripForCesiumView()
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
