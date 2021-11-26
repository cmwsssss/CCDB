//
//  CCModelConfiguration.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/16.
//

import Foundation

struct CCModelConfiguration {
    var modelInit: (()->Any)?
    var intoDBMapper : ((Any)->String)?
    var outDBMapper : ((Any, String)->())?
    var inOutPropertiesMapper = [String: Bool]()
    var publishedTypeMapper = [String: Any.Type]()
}
