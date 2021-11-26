//
//  CCModelSavingable+index.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/19.
//

import Foundation

extension CCModelSavingable {
    static func _createIndex(propertyName: String) {
        let typeName = String(describing: Self.self)
        let sql = "CREATE INDEX \(propertyName)_\(typeName)_index ON \(typeName) (\(propertyName))"
        let dbInstance = CCDBInstancePool.shared.getATransaction()
        dbInstance.queue.sync {
            let stmt = CCDBConnection.statementWithSql(sql, instance: dbInstance)
            stmt.step()
            stmt.reset()
        }
    }
    
    static func _removeIndex(propertyName: String) {
        let typeName = String(describing: Self.self)
        let sql = "Drop INDEX \(propertyName)_\(typeName)_index"
        let dbInstance = CCDBInstancePool.shared.getATransaction()
        dbInstance.queue.sync {
            let stmt = CCDBConnection.statementWithSql(sql, instance: dbInstance)
            stmt.step()
            stmt.reset()
        }
    }
}
