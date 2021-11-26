//
//  CCModelSavingable+update.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/15.
//

import Foundation
import SQLite3
import Combine
extension CCModelSavingable {
    func createReplaceIntoDBSql(withProperties properties: [Property.Description], typeName: String, propertyMapper: CCModelPropertyMapper) -> String {
        var sql = "replace into \(typeName) ("
        var tailPartSql = "("
        var first = true
        for property in properties {
            if let inOutProperty = propertyMapper.inOutPropertiesMapper[property.key], inOutProperty == true {
                continue
            }
            if !first {
                sql = sql + ", "
                tailPartSql = tailPartSql + ", "
            }
            first = false
            sql = sql + "\(property.key)"
            tailPartSql = tailPartSql + "?"
        }
        sql += ", CUSTOM_INOUT_PROPERTIES"
        tailPartSql = tailPartSql + ",?);"
        sql = sql + ") values \(tailPartSql)"
        return sql
    }
    
    func replaceBasicPropertyIntoDB(value: Any, columnType: CCDBColumnType, index: Int32, stmt: CCDBStatement) {
        let bind = stmt.bindValue(columnType)
        switch bind {
            case let .CCDBStatementBindTypeBool(bindBool):
                bindBool(index, value as? Bool ?? false)
            case let .CCDBStatementBindTypeInt(bindInt32):
                bindInt32(index, Int32(value as? Int ?? 0))
            case let .CCDBStatementBindTypeLong(bindInt64):
                bindInt64(index,Int64(value as? Int ?? 0))
            case let .CCDBStatementBindTypeDouble(bindDouble):
                bindDouble(index, value as? Double ?? 0)
            case let .CCDBStatementBindTypeString(bindString):
                bindString(index, value as? String ?? "")
        }
    }
    
    func replaceCustomObjectIntoDB(value: Any, type: Any.Type, index: Int32, stmt: CCDBStatement) {
        var instance = value as? CCModelSavingable
        instance?.replaceIntoDB()
        guard let propertyMapper = CCModelMapperManager.shared.getMapperWithType(type) else {
            return
        }
        let rawPointer = instance?.headPointer()
        let properties = propertyMapper.properties
        let primaryProperty = properties[0]
        guard let propAddr = rawPointer?.advanced(by: primaryProperty.offset) else {
            return
        }
        let propertyDetail = PropertyInfo(key: primaryProperty.key, type: primaryProperty.type, address: propAddr, bridged: false)
        guard let propertyValue = extensions(of: propertyDetail.type).value(from: propertyDetail.address) else {
            return
        }
        let desc = String(describing: propertyDetail.type)
        var finalValue = propertyValue
        if desc.contains("Published") {
            if let currentValue = Self.findPublisherCurrentValue(value: propertyValue, finalLevel: false) {
                finalValue = currentValue
            }
        }
        guard let columnType = propertyMapper.columnType[primaryProperty.key] else {
            return
        }
        
        let bind = stmt.bindValue(columnType)
        switch bind {
            case let .CCDBStatementBindTypeBool(bindBool):
                bindBool(index, finalValue as? Bool ?? false)
            case let .CCDBStatementBindTypeInt(bindInt32):
                bindInt32(index, Int32(finalValue as? Int ?? 0))
            case let .CCDBStatementBindTypeLong(bindInt64):
                bindInt64(index,Int64(finalValue as? Int ?? 0))
            case let .CCDBStatementBindTypeDouble(bindDouble):
                bindDouble(index, finalValue as? Double ?? 0)
            case let .CCDBStatementBindTypeString(bindString):
                bindString(index, finalValue as? String ?? "")
        }
    }
    
    func _replaceIntoDB(dbInstance: CCDBInstance, containerId: Int, top: Bool) {
        let typeName = String(describing: Self.self)
        let propertyMapper = CCModelMapperManager.shared.getMapperWithType(Self.self)
        let containerTableName = "\(typeName)_index"
        var timestamp :TimeInterval = Date.init().timeIntervalSince1970
        
        if top {
            if let minUpdateTime = propertyMapper?.containerMinUpdateTime[containerId] {
                timestamp = minUpdateTime - 1
            } else {
                let sql = "SELECT min(update_time) from \(containerTableName) where hash_id = \(containerId)"
                let stmt = CCDBConnection.statementWithSql(sql, instance: dbInstance)
                if stmt.step() == SQLITE_ROW {
                    let getValue = stmt.getValue(.CCDBColumnTypeDouble)
                    switch getValue {
                    case let .CCDBStatementReturnTypeDouble(getDouble):
                        timestamp = Self.decodeDoubleType(value:getDouble(0), targetType:Double.self) as! Double
                        timestamp = timestamp - 1
                    default:
                        return
                    }
                }
                stmt.reset()
            }
        }
        propertyMapper?.containerMinUpdateTime[containerId] = timestamp
        
        let sql = "REPLACE INTO \(containerTableName) (id,hash_id,primarykey,update_time) VALUES(?,?,?,?)"
        let stmt = CCDBConnection.statementWithSql(sql, instance: dbInstance)
        
        stmt.bindInt32(index: 2, withValue: Int32(containerId))
        
        guard let primaryProperty = propertyMapper?.properties[0] else {
            return
        }

        
        let mirror:Mirror = Mirror(reflecting: self)
        let primaryValue = mirror.children[mirror.children.startIndex].value
        
        switch propertyMapper?.columnType[primaryProperty.key] {
        case .CCDBColumnTypeInt:
            guard let value = primaryValue as? Int else {
                return
            }
            stmt.bindInt32(index: 3, withValue: Int32(value))
            stmt.bindString(index: 1, withValue: "\(value)-\(containerId)")
        case .CCDBColumnTypeLong:
            guard let value = primaryValue as? Int else {
                return
            }
            stmt.bindInt64(index: 3, withValue: Int64(value))
            stmt.bindString(index: 1, withValue: "\(value)-\(containerId)")
        case .CCDBColumnTypeDouble:
            guard let value = primaryValue as? Double else {
                return
            }
            stmt.bindDouble(index: 3, withValue: value)
            stmt.bindString(index: 1, withValue: "\(value)-\(containerId)")
        case .CCDBColumnTypeString:
            guard let value = primaryValue as? String else {
                return
            }
            stmt.bindString(index: 3, withValue: value)
            stmt.bindString(index: 1, withValue: "\(value)-\(containerId)")
        default:
            return
        }
        stmt.bindDouble(index: 4, withValue: timestamp)
        stmt.step()
        stmt.reset()
        self._replaceIntoDB(dbInstance: dbInstance)
    }
    
    static func findPublisherCurrentValue(value: Any, finalLevel: Bool) -> Any? {
        let mirror = Mirror(reflecting: value)
        if finalLevel {
            for child in mirror.children {
                if child.label == "currentValue" || child.label == "value" {
                    return child.value
                }
            }
        } else {
            for child in mirror.children {
                if child.label == "currentValue" || child.label == "value" {
                    return child.value
                }
                else {
                    if child.label == "subject" {
                        if let finalValue = findPublisherCurrentValue(value: child.value, finalLevel: true) {
                            return finalValue
                        }
                    } else {
                        if let finalValue = findPublisherCurrentValue(value: child.value, finalLevel: false) {
                            return finalValue
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func _replaceIntoDB(dbInstance: CCDBInstance) {
        let typeName = String(describing: Self.self)
        guard let mapper = CCModelMapperManager.shared.getMapperWithType(Self.self) else {
            return
        }
        var instance = self
        let rawPointer = instance.headPointer()
        let properties = mapper.properties
        var sql = mapper.replaceSql
        if sql == nil {
            sql = createReplaceIntoDBSql(withProperties: properties, typeName: typeName, propertyMapper: mapper)
            mapper.replaceSql = sql
        }
        let stmt = CCDBConnection.statementWithSql(sql!, instance: dbInstance)
        var index : Int32 = 1
        for property in properties {
            
            if mapper.inOutPropertiesMapper[property.key] != nil {
                continue
            }

            let propAddr = rawPointer.advanced(by: property.offset)
            
            let propertyDetail = PropertyInfo(key: property.key, type: property.type, address: propAddr, bridged: false)
            
            guard let columnType = mapper.columnType[property.key] else {
                return
            }
            
            guard let value = extensions(of: property.type).value(from: propertyDetail.address) else {
                return
            }
            let desc = String(describing: property.type)
            var finalValue = value
            if desc.contains("Published") {
                if let currentValue = Self.findPublisherCurrentValue(value: value, finalLevel: false) {
                    finalValue = currentValue
                }
            }
            
            switch columnType {
            case.CCDBColumnTypeDouble:
                self.replaceBasicPropertyIntoDB(value: finalValue,
                                                    columnType: columnType,
                                                    index: index,
                                                    stmt: stmt)
            case .CCDBColumnTypeInt:
                self.replaceBasicPropertyIntoDB(value: finalValue,
                                                    columnType: columnType,
                                                    index: index,
                                                    stmt: stmt)
            case .CCDBColumnTypeLong:
                self.replaceBasicPropertyIntoDB(value: finalValue,
                                                    columnType: columnType,
                                                    index: index,
                                                    stmt: stmt)
            case .CCDBColumnTypeBool:
                self.replaceBasicPropertyIntoDB(value: finalValue,
                                                    columnType: columnType,
                                                    index: index,
                                                    stmt: stmt)
            case .CCDBColumnTypeString:
                self.replaceBasicPropertyIntoDB(value: finalValue,
                                                    columnType: columnType,
                                                    index: index,
                                                    stmt: stmt)
            case .CCDBColumnTypeCustom:
                var type1 = property.type
                if let realType = mapper.publishedTypeMapper[property.key] {
                    type1 = realType
                }
                self.replaceCustomObjectIntoDB(value: finalValue,
                                               type: type1,
                                               index: index,
                                               stmt: stmt)
            }
            index = index + 1
        }
        
        if let intoDBFunc = mapper.intoDBMapper {
            self.replaceBasicPropertyIntoDB(value: intoDBFunc(instance), columnType: .CCDBColumnTypeString, index: index, stmt: stmt)
        }
        let res = stmt.step()
        if res != SQLITE_DONE {
            assertionFailure("error1: \(res)")
        }
        stmt.reset()
    }
}
