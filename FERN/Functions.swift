//
//  Functions.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//

import Foundation
import SwiftUI

// To allow a live preview in Xcode for debugging. From https://developer.apple.com/forums/thread/118589
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

//// View extension for alignment by ratios. Help from https://www.swiftbysundell.com/articles/swiftui-layout-system-guide-part-3/
//// May need to add an adjusting value depending which device is being used
//extension View {
//    func alignByRatio(horizRatio: Double, vertRatio: Double,
//                      alignment: Alignment = .center) -> some View {
//        alignmentGuide(HorizontalAlignment.center) {
//            $0.width * horizRatio
//        }
//        .alignmentGuide(VerticalAlignment.center) {
//            $0.height * vertRatio
//        }
//    }
//}
