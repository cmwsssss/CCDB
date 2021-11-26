//
//  CompareModel.swift
//  CCModelExample
//
//  Created by cmw on 2021/11/19.
//

import Foundation

class CompareModel: CCModelSavingable {
    var compareId = 0
    var param1 = "param1"
    var param2 = 2
    var param3 = 3.1
    var param4 = false
    var param5 = "param5"
    var param6 = "param6"
    var param7 = "param7"
    
    static func modelConfiguration() -> CCModelConfiguration {
        var config = CCModelConfiguration()
        config.modelInit = CompareModel.init
        return config
    }
}
