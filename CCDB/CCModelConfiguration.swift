//
//  CCModelConfiguration.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/16.
//

import Foundation

public struct CCModelConfiguration {
    
    public init(modelInit: @escaping ()->Any) {
        self.modelInit = modelInit
    }
    
    public var modelInit: (()->Any)
    public var intoDBMapper : ((Any)->String)?
    public var outDBMapper : ((Any, String)->())?
    public var inOutPropertiesMapper = [String: Bool]()
    public var publishedTypeMapper = [String: Any.Type]()
    public var cachePolicy = CCModelCachePolicy.fastQueryAndUpdate
}
