//
//  CCModedlSavingable+query.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/15.
//

import Foundation
import SQLite3

extension CCModelSavingable {
    
    private static func createSelectHeaderPart(propertyMapper: CCModelPropertyMapper, typeName: String, joinTableName:String?) -> String {
        var sql = "SELECT "
        var first = true
        for property in propertyMapper.properties {
            if let inOutProperty = propertyMapper.inOutPropertiesMapper[property.key], inOutProperty == true {
                continue
            }
            sql = (first) ? sql + property.key : sql + ",\(property.key)"
            first = false
        }
        sql = sql + ", CUSTOM_INOUT_PROPERTIES"
        sql = sql + " FROM \(typeName)"
        guard let joinName = joinTableName else {
            return sql
        }
        sql = sql + ", \(joinName) as i"
        return sql
    }
    
    private static func createSelectSql(withProperties properties: [Property.Description], typeName: String, propertyMapper: CCModelPropertyMapper) -> String {
        var sql = "select "
        var first = true
        for property in properties {
            if let inOutProperty = propertyMapper.inOutPropertiesMapper[property.key], inOutProperty == true {
                continue
            }
            if !first {
                sql = sql + ","
            }
            first = false
            sql = sql + "\(property.key)"
        }
        sql = sql + ", CUSTOM_INOUT_PROPERTIES"
        sql = sql + " from \(typeName) where \(properties[0].key) = ?"
        return sql
    }
    
    private static func getPrimaryValueFromCustomPrimaryProperty(stmt: CCDBStatement, index: Int32, type: Any.Type, dbInstance: CCDBInstance) -> Any? {
        
        guard let propertyMapper = CCModelMapperManager.shared.getMapperWithType(type) else {
            return nil
        }
        
        guard let primaryColumnType = propertyMapper.columnType[propertyMapper.properties[0].key] else {
            return nil
        }
        
        let getPrimaryValue = stmt.getValue(primaryColumnType)
        var value :Any
        switch getPrimaryValue {
            case let .CCDBStatementReturnTypeBool(getBool):
                value = getBool(index)
            case let .CCDBStatementReturnTypeInt(getInt32):
                value = getInt32(index)
            case let .CCDBStatementReturnTypeLong(getInt64):
                value = getInt64(index)
            case let .CCDBStatementReturnTypeDouble(getDouble):
                value = getDouble(index)
            case let .CCDBStatementReturnTypeString(getString):
                value = getString(index)
        }
        
        return value
        
    }
    
    private static func setupFromStmt(stmt: CCDBStatement, object :inout Any, properties: [Property.Description], dbInstance: CCDBInstance) -> [String :(propertyDetail: PropertyInfo, primaryValue:AnyHashable)]? {
        guard let propertyMapper = CCModelMapperManager.shared.getMapperWithType(Self.self) else {
            return nil
        }
        var instance = object as? CCModelSavingable
        guard let rawPointer = instance?.headPointer() else {
            return nil
        }
        
        var needSetupCustomObjects = [String :(propertyDetail: PropertyInfo, primaryValue:AnyHashable)]()
        
        var index :Int32 = 0
        for property in properties {
            
            if let needInout = propertyMapper.inOutPropertiesMapper[property.key], needInout == true {
                continue
            }

            let propAddr = rawPointer.advanced(by: property.offset)
            var type = property.type
            if let realType = propertyMapper.publishedTypeMapper[property.key] {
                type = realType
            }
            
            let propertyDetail = PropertyInfo(key: property.key, type: type, address: propAddr, bridged: false)
            if let columnType = propertyMapper.columnType[property.key] {
                let getValue = stmt.getValue(columnType)
                switch columnType {
                case .CCDBColumnTypeInt, .CCDBColumnTypeLong, .CCDBColumnTypeDouble, .CCDBColumnTypeString, .CCDBColumnTypeBool:
                    switch getValue {
                    case let.CCDBStatementReturnTypeBool(getBool):
                        let value = getBool(index)
                        extensions(of: type).write(value, to: propertyDetail.address)
                    case let.CCDBStatementReturnTypeInt(getInt32):
                        if let value = decodeInt32Type(value:getInt32(index), targetType:Int.self) {
                            extensions(of: type).write(value, to: propertyDetail.address)
                        }
                    case let .CCDBStatementReturnTypeLong(getInt64):
                        if let value = decodeInt64Type(value:getInt64(index), targetType:Int64.self) {
                            extensions(of: type).write(value, to: propertyDetail.address)
                        }
                    case let .CCDBStatementReturnTypeDouble(getDouble):
                        if let value = decodeDoubleType(value:getDouble(index), targetType:Double.self) {
                            extensions(of: type).write(value, to: propertyDetail.address)
                        }
                    case let .CCDBStatementReturnTypeString(getString):
                        let value = getString(index)
                        extensions(of: type).write(value, to: propertyDetail.address)
                    }
                case .CCDBColumnTypeCustom:
                    
                    let value = getPrimaryValueFromCustomPrimaryProperty(stmt: stmt,
                                                                  index: index,
                                                                  type: type,
                                                                  dbInstance: dbInstance)
                    if let primaryValue = value as? AnyHashable {
                        needSetupCustomObjects[propertyDetail.key] = (propertyDetail, primaryValue)
                    }
                }
            }
            
            index = index + 1
        }
        
        let getValue = stmt.getValue(.CCDBColumnTypeString)
        switch getValue {
        case let .CCDBStatementReturnTypeString(getString):
            let value = getString(index)
            if let outFunc = propertyMapper.outDBMapper {
                outFunc(instance, value)
            }
        default:
            break
        }
        
        
        
        return needSetupCustomObjects
    }
    
    static func setupCustomObjects(objects: [String :(propertyDetail: PropertyInfo, primaryValue:AnyHashable)], dbInstance: CCDBInstance) {
        for (_, value) in objects {
            
            guard let propertyMapper = CCModelMapperManager.shared.getMapperWithType(value.propertyDetail.type) else {
                return
            }
            
            guard let modelInit = propertyMapper.modelInit else {
                return
            }
            
            var object = modelInit()
            if let objectType = type(of: object) as? CCModelSavingable.Type {
                object = objectType.initWithPrimaryPropertyValue(value.primaryValue) ?? modelInit()
            }
            propertyMapper.needNotifierObject.append(object as! CCModelSavingable)
            
//            self.updateWithDBData(object: &object, primaryValue: value.primaryValue, propertyMapper: propertyMapper, type:value.propertyDetail.type, dbInstance: dbInstance)
            
            extensions(of: value.propertyDetail.type).write(object, to: value.propertyDetail.address)
        }
    }
        
    static func updateWithDBData(object:inout Any, primaryValue: AnyHashable, propertyMapper:CCModelPropertyMapper, type: Any.Type, dbInstance: CCDBInstance) {
        
        let typeName = String(describing: type)
        
        let properties = propertyMapper.properties
        let sql = propertyMapper.initSql ?? createSelectSql(withProperties: properties, typeName: typeName, propertyMapper: propertyMapper)
        if propertyMapper.initSql == nil {
            propertyMapper.initSql = sql
        }
        
        let primaryProprety = properties[0]
        let stmt = CCDBConnection.statementWithSql(sql, instance: dbInstance)
        let columnType = propertyMapper.columnType[primaryProprety.key]
        let bind = stmt.bindValue(columnType!)
        switch bind {
            case let .CCDBStatementBindTypeBool(bindBool):
                bindBool(1, primaryValue as? Bool ?? false)
            case let .CCDBStatementBindTypeInt(bindInt32):
                bindInt32(1, Int32(primaryValue as? Int ?? 0))
            case let .CCDBStatementBindTypeLong(bindInt64):
                bindInt64(1, Int64(primaryValue as? Int ?? 0))
            case let .CCDBStatementBindTypeDouble(bindDouble):
                bindDouble(1, primaryValue as? Double ?? 0)
            case let .CCDBStatementBindTypeString(bindString):
                bindString(1, primaryValue as? String ?? "")
        }
        var needSetupCustomObjects:  [String :(propertyDetail: PropertyInfo, primaryValue:AnyHashable)]?
        
        if (stmt.step() == SQLITE_ROW) {
            let modelType = type as? CCModelSavingable.Type
            needSetupCustomObjects = modelType?.setupFromStmt(stmt: stmt, object: &object, properties: properties, dbInstance: dbInstance)
        }
        
        stmt.reset()
        
        guard let objects = needSetupCustomObjects else {
            return
        }
        
        self.setupCustomObjects(objects: objects, dbInstance: dbInstance)
    }
    
    static func _initWithPrimaryPropertyValue(_ value: AnyHashable, dbInstance: CCDBInstance) -> Self? {
        guard let propertyMapper = CCModelMapperManager.shared.getMapperWithType(Self.self) else {
            return nil
        }
        guard let modelInit = propertyMapper.modelInit else {
            return nil
        }
        var object = modelInit()
        propertyMapper.needNotifierObject.append(object as! CCModelSavingable)
        self.updateWithDBData(object: &object, primaryValue: value, propertyMapper: propertyMapper, type: Self.self, dbInstance: dbInstance)
        guard let res = object as? Self else {
            return nil
        }
        return res
    }
    
    static func _initWithPrimaryPropertyValue(_ value: AnyHashable) -> Self? {
        var res :Self?
        let name = __dispatch_queue_get_label(nil)
        if let labelName = String(cString: name, encoding: .utf8), labelName.hasPrefix("CCDB"), let lastC = labelName.last, let index = Int(String(lastC)) {
            let dbInstance = CCDBInstancePool.shared.getTransaction(index: index)
            res = _initWithPrimaryPropertyValue(value, dbInstance: dbInstance)
        } else {
            let dbInstance = CCDBInstancePool.shared.getATransaction()
            dbInstance.queue.sync {
                res = _initWithPrimaryPropertyValue(value, dbInstance: dbInstance)
            }
        }
        return res
    }
    
    static func _count(condition: CCDBCondition) -> Int {
        let date = Date()
        let typeName = String(describing: Self.self)
        var sql = "SELECT COUNT(*) from "
        if condition.containerId != 0 {
            guard let propertyMapper = CCModelMapperManager.shared.getMapperWithType(Self.self) else {
                return 0
            }
            
            if let whereSql = condition.whereSql {
                sql = sql + "\(typeName) , \(typeName)_index as i where \(typeName).\(propertyMapper.properties[0].key) = i.primarykey and i.hash_id = \(condition.containerId)"
                sql = sql + " AND \(whereSql)"
            } else {
                sql = sql + " \(typeName)_index as i where i.hash_id = \(condition.containerId)"
            }
        } else {
            sql = sql + " \(typeName) "
            if let whereSql = condition.whereSql {
                sql = sql + " WHERE \(whereSql)"
            }
        }
        let dbInstance = CCDBInstancePool.shared.getATransaction()
        var res = 0
        dbInstance.queue.sync {
            let stmt = CCDBConnection.statementWithSql(sql, instance: dbInstance)
            while (stmt.step() == SQLITE_ROW) {
                let getValue = stmt.getValue(.CCDBColumnTypeInt)
                switch getValue {
                case let .CCDBStatementReturnTypeInt(getInt32):
                    res = decodeInt32Type(value:getInt32(0), targetType:Int.self) as! Int
                default:
                    res = 0
                }
            }
            stmt.reset()
        }
        print("countTime:\(date.timeIntervalSinceNow)")
        return res
    }
    
    static func queryForChunkWithJoin(sql: String, dbInstance: CCDBInstance, propertyMapper: CCModelPropertyMapper) -> [Self] {
        var datas = [Self]()
        let stmt = CCDBConnection.statementWithSql(sql, instance: dbInstance)
        while stmt.step() == SQLITE_ROW {
            guard let modelInit = propertyMapper.modelInit else {
                return [Self]()
            }
            var object = modelInit()
            let needSetupCustomObjects = self.setupFromStmt(stmt: stmt, object: &object, properties: propertyMapper.properties, dbInstance: dbInstance)
            
            guard let objects = needSetupCustomObjects else {
                return [Self]()
            }
            
            self.setupCustomObjects(objects: objects, dbInstance: dbInstance)
            
            guard let res = object as? Self else {
                return [Self]()
            }
            datas.append(res)
        }
        stmt.reset()
        return datas
    }
    
    static func queryForChunk(sql: String, dbInstance: CCDBInstance, propertyMapper: CCModelPropertyMapper) -> [Self] {
        var datas = [Self]()
        let stmt = CCDBConnection.statementWithSql(sql, instance: dbInstance)
        while stmt.step() == SQLITE_ROW {
            let value = getPrimaryValueFromCustomPrimaryProperty(stmt: stmt,
                                                          index: 0,
                                                          type: Self.self,
                                                          dbInstance: dbInstance)
            if let primaryValue = value as? AnyHashable {
                guard let res = _initWithPrimaryPropertyValue(primaryValue, dbInstance: dbInstance) else { continue
                }
                datas.append(res)
            }
        }
        stmt.reset()
        return datas
    }
    
    static func _query(condition: CCDBCondition) -> [Self] {
        let typeName = String(describing: Self.self)
        var count = 0
        var offset = 0
        if let conditionLimit = condition.limit {
            count = conditionLimit
        } else {
            count = self.count(condition)
        }
        if let conditionOffset = condition.offset {
            offset = conditionOffset
        } else {
            offset = 0
        }
        
        var limit = count / CCDBInstancePool.DB_INSTANCE_POOL_SIZE
        limit = (limit == 0) ? 1 : limit
        condition.ccLimit(limit: limit)
        let semaphore = DispatchSemaphore.init(value: 1)
        guard let propertyMapper = CCModelMapperManager.shared.getMapperWithType(Self.self) else {
            return [Self]()
        }
        
        let joinTableName: String? = (condition.containerId != 0) ? "\(typeName)_index" : nil
        let headerPartSql = self.createSelectHeaderPart(propertyMapper: propertyMapper, typeName: typeName, joinTableName: joinTableName)
        let queue = DispatchQueue.init(label: "queryQueue", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .never, target: nil)
        var dicIndex = [Int: [Self]]()
        var chunkOffset = offset
        for i in 0..<CCDBInstancePool.DB_INSTANCE_POOL_SIZE {
            let subCondition = condition.copyInstance
            if i == CCDBInstancePool.DB_INSTANCE_POOL_SIZE - 1 {
                subCondition.ccLimit(limit: count)
            }
            subCondition.ccOffset(offset: chunkOffset)
            chunkOffset += limit
            queue.async {
                var sql = headerPartSql
                
                if subCondition.containerId != 0 {
                    if subCondition.whereSql != nil {
                        sql = sql + " where \(typeName).\(propertyMapper.properties[0].key) = i.primarykey and i.hash_id = \(subCondition.containerId)"
                        sql = sql + subCondition.sql
                    } else {
                        sql = "SELECT primaryKey from \(typeName)_index as i WHERE i.hash_id = \(subCondition.containerId) \(subCondition.sql)"
                    }
                    
                } else {
                    if subCondition.whereSql != nil {
                        sql = sql + " where \(subCondition.sql)"
                    } else {
                        sql = sql + subCondition.sql
                    }
                }

                let dbInstance = CCDBInstancePool.shared.getATransaction()
                var datas = [Self]()
                dbInstance.queue.sync {
                    let date = Date()
                    print("startCheck")
                    if subCondition.containerId != 0 {
                        if subCondition.whereSql != nil {
                            datas = self.queryForChunkWithJoin(sql: sql, dbInstance: dbInstance, propertyMapper: propertyMapper)
                        } else {
                            datas = self.queryForChunk(sql: sql, dbInstance: dbInstance, propertyMapper: propertyMapper)
                        }
                    } else {
                        datas = self.queryForChunkWithJoin(sql: sql, dbInstance: dbInstance, propertyMapper: propertyMapper)
                    }
                    print("chunkDate \(date.timeIntervalSinceNow)")
                }
                semaphore.wait()
                guard let subOffset = subCondition.offset else {
                    return
                }
                dicIndex[subOffset] = datas
                semaphore.signal()
            }
        }
        
        var res = [Self]()
        queue.sync(flags: .barrier) {
            var subOffset = offset
            for _ in 0..<CCDBInstancePool.DB_INSTANCE_POOL_SIZE {
                if let subDatas = dicIndex[subOffset] {
                    res.append(contentsOf: subDatas)
                }
                subOffset = subOffset + limit
            }
        };
        
        return res
    }
}

