//
//  Functions.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//

import Foundation
import SwiftUI

// To allow a live preview in Xcode for debugging. From https://developer.apple.com/forums/thread/118589
// However, the supplied NMEA toolkit was not compiled with the required arm(?) for a live preview.
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    var body: some View {
        content($value)
    }

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(wrappedValue: value)
        self.content = content
    }
}
