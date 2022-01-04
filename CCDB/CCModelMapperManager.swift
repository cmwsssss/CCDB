//
//  CCModelMapperManager.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/9.
//

import Foundation

public class CCModelPropertyMapper {
    var properties: [Property.Description] = Array()
    var columnType: [String: CCDBColumnType] = Dictionary()
    var intoDBMapper : ((Any)->String)?
    var outDBMapper : ((Any, String)->())?
    var inOutPropertiesMapper = [String: Bool]()
    var publishedTypeMapper = [String: Any.Type]()
    var containerMinUpdateTime: [Int: Double] = Dictionary()
    var modelInit: (()->Any)?
    var replaceSql: String?
    var initSql: String?
    var viewNotifier = [()->Void]()
    var needNotifierObject = [CCModelSavingable]()
    var mmapIndex = -1
    var cachePolicy = CCModelCachePolicy.fastQueryAndUpdate
    var memoryCacheInited = false
    var containerMemoryCacheInited = [AnyHashable: Bool]()
    var cacheQueue = DispatchQueue(label: "cacheQueue")
    var cacheChangeSemaphore = DispatchSemaphore(value: 1)
}

class CCModelMapperManager {
    static let shared = CCModelMapperManager()
    private var dicModelPropertyMapper : [String : CCModelPropertyMapper] = Dictionary()
    var notifierSem = DispatchSemaphore(value: 1)
    var initSem = DispatchSemaphore(value: 1)
    
    func getColumnType(fromType type:Any.Type) -> CCDBColumnType {
        if (String(describing: type).contains("String")) {
            return CCDBColumnType.CCDBColumnTypeString
        } else if (String(describing: type).contains("Int64")) {
            return CCDBColumnType.CCDBColumnTypeLong
        } else if (String(describing: type).contains("Double")) {
            return CCDBColumnType.CCDBColumnTypeDouble
        } else if (String(describing: type).contains("Int")) {
            return CCDBColumnType.CCDBColumnTypeInt
        } else if (String(describing: type).contains("Bool")) {
            return CCDBColumnType.CCDBColumnTypeBool
        }
        return CCDBColumnType.CCDBColumnTypeCustom
    }
    
    func getMapperWithTypeName(_ typeName: String, type: Any.Type) -> CCModelPropertyMapper? {
        guard let mapper = self.dicModelPropertyMapper[typeName] else {
            return self.initializeMapperWithType(type, typeName: typeName)
        }
        return mapper
    }
    
    func getMapperWithType(_ type: Any.Type) -> CCModelPropertyMapper? {
        let typeName = String(describing: type)
        guard let mapper = self.dicModelPropertyMapper[typeName] else {
            return self.initializeMapperWithType(type, typeName: typeName)
        }
        return mapper
    }
    
    func initializeMapperWithType(_ type: Any.Type, typeName:String) -> CCModelPropertyMapper? {
        if let mapper = self.dicModelPropertyMapper[typeName] {
            return mapper
        }
        guard let properties = getProperties(forType: type) else {
            return nil
        }
        self.initSem.wait()
        let mapper = CCModelPropertyMapper()
        mapper.properties = properties
        
        let realType = type as? CCModelSavingable.Type
        let modelConfiguration = realType?.modelConfiguration()
        if let publishedMapper = modelConfiguration?.publishedTypeMapper {
            mapper.publishedTypeMapper = publishedMapper
        }
        for property in properties {
            mapper.columnType[property.key] = getColumnType(fromType: property.type)
        }
        mapper.modelInit = modelConfiguration?.modelInit
        mapper.outDBMapper = modelConfiguration?.outDBMapper
        mapper.intoDBMapper = modelConfiguration?.intoDBMapper
        if let cachePolicy = modelConfiguration?.cachePolicy {
            mapper.cachePolicy = cachePolicy
        }
        if let inOutMapper = modelConfiguration?.inOutPropertiesMapper {
            mapper.inOutPropertiesMapper = inOutMapper
        }
        mapper.mmapIndex = Int(ccdb_initilizeMMAPCache(typeName))
        self.dicModelPropertyMapper[typeName] = mapper
        self.initSem.signal()
        return mapper
    }
}

