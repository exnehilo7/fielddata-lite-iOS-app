//
//  Test_OvsvObj.swift
//  FERN
//
//  Created by Hopp, Dan on 2/6/23.
//

import SwiftUI

struct Test_OvsvObj: View {
    
    @ObservedObject var willItWork: Temp_MapPointModel_ObsvObj
    
    
    var body: some View {
        Button("See Obj") {
            print(willItWork.self)
            print(willItWork.geoPoint)
        }
    }
    
//    List (willItWork, id: \.id) { (result) in
//        HStack {
//            //Text(result.siteId ?? 0)
//            Text(result.organismName)
//            Text(result.geoPoint)
//            Text(result.siteId)
//            // try placing in an obsv obj?
//
//        }
//    }
}

//struct Test_OvsvObj_Previews: PreviewProvider {
//    static var previews: some View {
//        Test_OvsvObj()
//    }
//}
