//
//  CCDBModel.swift
//  SpeedTest
//
//  Created by cmw on 2021/12/13.
//

import Foundation
import CCDB
class CCDBModel: CCModelSavingable {
    var compareId = 0
    var param1 = "param1"
    var param2 = 2
    var param3 = 3.1
    var param4 = false
    var param5 = "param5"
    var param6 = "param6"
    var param7 = "param7"
    
    static func modelConfiguration() -> CCModelConfiguration {
        var modelConfg = CCModelConfiguration(modelInit: CCDBModel.init)
        return modelConfg
    }
    
    static func fastModelIndex() -> String {
        return "CCDBModel"
    }
}
