//
//  MapView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//  Map basics help from https://www.mongodb.com/developer/products/realm/realm-swiftui-maps-location/

import SwiftUI
import MapKit


struct MapView: View {
    
    // Set startig geo loc
    private enum MapDefaults {
        static let latitude = 35.93212
        static let longitude = -84.31022
        static let zoom = 0.05
    }

    
    // Make some test points (aka "annotations"). Note that this is using a struct in Models
    let annotationItems = [
        MapAnnotationItem(coordinate: CLLocationCoordinate2D(
            latitude: MapDefaults.latitude,
            longitude: MapDefaults.longitude)),
        MapAnnotationItem(coordinate: CLLocationCoordinate2D(
            latitude: 35.931,
            longitude: -84.31528)),
          MapAnnotationItem(coordinate: CLLocationCoordinate2D(
              latitude: 35.915,
              longitude: -84.31728))
    ]
    
    // Set general region at launch
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
           center: CLLocationCoordinate2D(latitude: MapDefaults.latitude, longitude: MapDefaults.longitude),
           span: MKCoordinateSpan(latitudeDelta: MapDefaults.zoom, longitudeDelta: MapDefaults.zoom))
        
//    // Try to pass values into a class
//    @StateObject var searchResults = MapPointModel(coordinate: CLLocationCoordinate2D(latitude: 35.925,
//                                                   longitude: -84.32028))
    
       var body: some View {
           VStack {
               Text("lat: \(region.center.latitude), long: \(region.center.longitude). Zoom: \(region.span.latitudeDelta)")
               .font(.caption)
               .padding()
               Map(coordinateRegion: $region,
                   interactionModes: .all,
                   showsUserLocation: true,
                   annotationItems: annotationItems
               ) { item in
                   // A vanilla point:
//                    MapMarker(coordinate: item.coordinate)
                   
                   // Use for custom images and colors:
                   MapAnnotation(coordinate: item.coordinate) {
                           Image(systemName: "tree.circle") //leaf.circle
                           .symbolRenderingMode(.palette)
                           .foregroundStyle(.green, .red).font(.system(size: 35))
                            }
                }
           }
       }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
