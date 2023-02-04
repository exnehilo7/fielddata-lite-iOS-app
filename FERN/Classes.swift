//
//  Classes.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//

import Foundation

// Class object for items in SearchByNameView's results. Is selected default is true
class Plot: ObservableObject {
    var plotName = ""
    var isSelected = true
}
