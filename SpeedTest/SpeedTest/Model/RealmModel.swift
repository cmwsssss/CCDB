//
//  RealmModel.swift
//  SpeedTest
//
//  Created by cmw on 2021/12/13.
//

import Foundation
import RealmSwift

class RealmModel: Object {
    @objc dynamic var compareId = 0
    @objc dynamic var param1 = "param1"
    @objc dynamic var param2 = 2
    @objc dynamic var param3 = 3.1
    @objc dynamic var param4 = false
    @objc dynamic var param5 = "param5"
    @objc dynamic var param6 = "param6"
    @objc dynamic var param7 = "param7"
}
