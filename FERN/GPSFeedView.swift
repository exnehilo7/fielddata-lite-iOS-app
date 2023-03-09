//
//  GPSFeedView.swift
//  FERN
//
//  Created by Hopp, Dan on 3/9/23.
//

import SwiftUI

struct GPSFeedView: View {
    
    @State var latitude: String
    @State var longitude: String
    @State var altitude: String
    @State var xyAccuracy: String
    @State var gpsUsed: String
    @State var receiveText = []
    
    
    // Will it need inits?
    
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct GPSFeedView_Previews: PreviewProvider {
    static var previews: some View {
        GPSFeedView(latitude: "-00.00000000", longitude: "-00.00000000", altitude: "-00.00 M", xyAccuracy: "-00.00000000", gpsUsed: "00")
    }
}
