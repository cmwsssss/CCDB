//
//  CCModelSavingable+delete.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/19.
//

import Foundation

extension CCModelSavingable {
    
    static func _removeAll() {
        let typeName = String(describing: Self.self)
        let sql = "DELETE FROM \(typeName)"
        let dbInstance = CCDBInstancePool.shared.getATransaction()
        dbInstance.queue.sync {
            let stmt = CCDBConnection.statementWithSql(sql, instance: dbInstance)
            stmt.step()
            stmt.reset()
        }
    }
    
    static func _removeAll(containerId: Int) {
        let typeName = String(describing: Self.self)
        let sql = "DELETE FROM \(typeName)_index where hash_id = \(containerId)"
        let dbInstance = CCDBInstancePool.shared.getATransaction()
        dbInstance.queue.sync {
            let stmt = CCDBConnection.statementWithSql(sql, instance: dbInstance)
            stmt.step()
            stmt.reset()
        }
    }
    
    func _removeFromDB() {
        let typeName = String(describing: Self.self)
        let mirror:Mirror = Mirror(reflecting: self)
        let value = mirror.children[mirror.children.startIndex].value
        let propertyMapper = CCModelMapperManager.shared.getMapperWithType(Self.self)
        guard let key = propertyMapper?.properties[0].key else {
            return
        }
        let sql = "DELETE FROM \(typeName) WHERE \(key) = ? "
        let dbInstance = CCDBInstancePool.shared.getATransaction()
        
        dbInstance.queue.sync {
            let stmt = CCDBConnection.statementWithSql(sql, instance: dbInstance)
            guard let columnType = propertyMapper?.columnType[key] else {
                return
            }
            self.replaceBasicPropertyIntoDB(value: value, columnType: columnType, index: 1, stmt: stmt)
            stmt.step()
            stmt.reset()
        }
    }
    
    func _removeFromDB(containerId: Int) {
        let typeName = String(describing: Self.self)
        let mirror:Mirror = Mirror(reflecting: self)
        let value = mirror.children[mirror.children.startIndex].value
        let propertyMapper = CCModelMapperManager.shared.getMapperWithType(Self.self)
        guard let key = propertyMapper?.properties[0].key else {
            return
        }
        let sql = "DELETE FROM \(typeName)_index WHERE hash_id = ? AND primarykey = ?"
        let dbInstance = CCDBInstancePool.shared.getATransaction()
        
        dbInstance.queue.sync {
            let stmt = CCDBConnection.statementWithSql(sql, instance: dbInstance)
            guard let columnType = propertyMapper?.columnType[key] else {
                return
            }
            self.replaceBasicPropertyIntoDB(value: containerId, columnType: .CCDBColumnTypeInt, index: 1, stmt: stmt)
            self.replaceBasicPropertyIntoDB(value: value, columnType: columnType, index: 2, stmt: stmt)
            stmt.step()
            stmt.reset()
        }
    }
}
