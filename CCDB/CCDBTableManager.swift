//
//  CCDBTableManager.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/13.
//

import Foundation
import SQLite3
enum CCDBTableAction {
    case CCDBTableActionCreate(()->(Void))
    case CCDBTableActionUpgrade(()->(Void))
    case CCDBTableActionNone
}

class CCDBTableManager {
    static let shared = CCDBTableManager()
    var semphore = DispatchSemaphore(value: 1)
    
    var dicTableInitialized : [String : Bool] = Dictionary()
}

public protocol CCDBTableEditable {
    func nextEditTableAction(typeName: String)
}

public extension CCDBTableEditable {
    
    static private var createTableSql : String? {
        
        let typeName = String(describing: Self.self)
        guard let mapper = CCModelMapperManager.shared.getMapperWithType(Self.self) else {
            return nil
        }
        var sql = "CREATE TABLE IF NOT EXISTS \(typeName) (CUSTOM_INOUT_PROPERTIES TEXT "
        for property in mapper.properties {
            if let inOutProperty = mapper.inOutPropertiesMapper[property.key], inOutProperty == true {
                continue
            }
            sql = sql + ", "
            if let columnType = mapper.columnType[property.key] {
                switch columnType {
                case .CCDBColumnTypeInt, .CCDBColumnTypeLong, .CCDBColumnTypeBool:
                    sql = sql + "\(property.key) INTEGER "
                case .CCDBColumnTypeDouble:
                    sql = sql + "\(property.key) REAL "
                case .CCDBColumnTypeString:
                    sql = sql + "\(property.key) TEXT "
                case .CCDBColumnTypeCustom:
                    var type = property.type
                    if let realType = mapper.publishedTypeMapper[property.key] {
                        type = realType
                    }
                    guard let customMapper = CCModelMapperManager.shared.getMapperWithType(type) else {
                        return nil
                    }
                    if let primaryType = customMapper.columnType[customMapper.properties[0].key] {
                        switch primaryType {
                        case .CCDBColumnTypeLong, .CCDBColumnTypeInt:
                            sql = sql + "\(property.key) INTEGER "
                        case .CCDBColumnTypeDouble:
                            sql = sql + "\(property.key) REAL "
                        case .CCDBColumnTypeString:
                            sql = sql + "\(property.key) TEXT "
                        default:
                            continue
                        }
                    }
                }
            }
        }
        sql = sql + ", PRIMARY KEY(\(mapper.properties[0].key)));"
        return sql
    }
    
    static private var createTableContainerSql : String? {
        let typeName = String(describing: Self.self)
        guard let mapper =  CCModelMapperManager.shared.getMapperWithType(Self.self) else {
            return nil
        }
        let primaryProperty = mapper.properties[0]
        let columnType = mapper.columnType[primaryProperty.key]
        switch columnType {
        case .CCDBColumnTypeInt, .CCDBColumnTypeLong, .CCDBColumnTypeBool:
            return "CREATE TABLE IF NOT EXISTS \(typeName)_index (id TEXT, hash_id INTEGER, primary_key INTEGER, update_time REAL, PRIMARY KEY(id))";
        case .CCDBColumnTypeDouble:
            return "CREATE TABLE IF NOT EXISTS \(typeName)_index (id TEXT, hash_id INTEGER, primary_key REAL, update_time REAL, PRIMARY KEY(id))";
        case .CCDBColumnTypeString:
            return "CREATE TABLE IF NOT EXISTS \(typeName)_index (id TEXT, hash_id INTEGER, primary_key TEXT, update_time REAL, PRIMARY KEY(id))";
        default:
            return nil
        }
    }
    
    static private var dropTableSql: String? {
        let typeName = String(describing: Self.self)
        let sql = "DROP TABLE \(typeName)_cc_temp"
        return sql
    }
    
    static private var renameTableSql: String? {
        let typeName = String(describing: Self.self)
        let sql = "ALTER TABLE \(typeName) RENAME TO \(typeName)_cc_temp"
        return sql
    }
    
    static private var pragmaTableInfoSql: String? {
        let typeName = String(describing: Self.self)
        let sql = "PRAGMA table_info('\(typeName)_cc_temp')"
        return sql
    }
    
    static private func getInsertSql(columnDatas: [String]) -> String {
        let typeName = String(describing: Self.self)
        let columnNames = columnDatas.joined(separator: ",")
        let sql = "INSERT INTO \(typeName) (\(columnNames)) SELECT \(columnNames) from \(typeName)_cc_temp"
        return sql
    }
    
    static private func executeSql(sql: String, dbInstance instance: CCDBInstance) {
        let stmt = CCDBConnection.statementWithSql(sql, instance: instance)
        if stmt.step() != SQLITE_DONE {
            
        }
        if stmt.reset() != SQLITE_DONE {
            
        }
    }
            
    static private func getPragmaInfo(sql: String, dbInstance instance: CCDBInstance) -> [String] {
        let stmt = CCDBConnection.statementWithSql(sql, instance: instance)
        var res = [String]()
        while stmt.step() == SQLITE_ROW {
            let value = stmt.getValue(.CCDBColumnTypeString)
            switch value {
            case let .CCDBStatementReturnTypeString(getString):
                res.append(getString(1))
            default:
                continue
            }
        }
        return res
        
    }
    
    static private func createTable() {
        let name = __dispatch_queue_get_label(nil)
        if let labelName = String(cString: name, encoding: .utf8), labelName.hasPrefix("CCDB"), let lastC = labelName.last, let index = Int(String(lastC)) {
            let instance = CCDBInstancePool.shared.getTransaction(index: index)
            if let sql = self.createTableSql {
                self.executeSql(sql: sql, dbInstance: instance)
            }
            if let sql = self.createTableContainerSql {
                self.executeSql(sql: sql, dbInstance: instance)
            }
        } else {
            let instance = CCDBInstancePool.shared.getATransaction()
            instance.queue.sync {
                if let sql = self.createTableSql {
                    self.executeSql(sql: sql, dbInstance: instance)
                }
                if let sql = self.createTableContainerSql {
                    self.executeSql(sql: sql, dbInstance: instance)
                }
            }
        }
        
    }
    
    static private func updateTable() {
        CCDBUpdateManager.shared.waitInit()
        let instance = CCDBInstancePool.shared.getATransaction()
        instance.queue.sync {
            if let sql = self.renameTableSql {
                self.executeSql(sql: sql, dbInstance: instance)
            }
            
            if let sql = self.createTableSql {
                self.executeSql(sql: sql, dbInstance: instance)
            }
            
            if let sql = self.pragmaTableInfoSql {
                let info = self.getPragmaInfo(sql: sql, dbInstance: instance)
                let insertSql = self.getInsertSql(columnDatas: info)
                self.executeSql(sql: insertSql, dbInstance: instance)
                if let dropSql = self.dropTableSql {
                    self.executeSql(sql: dropSql, dbInstance: instance)
                }
            }
        }
    }
    
    static func nextEditTableAction(typeName: String) {
        CCDBTableManager.shared.semphore.wait()
        CCModelMapperManager.shared.initializeMapperWithType(Self.self,typeName: typeName)
        let nextAction = getNextTableAction(typeName: typeName)
        switch nextAction {
        case let .CCDBTableActionCreate(createTable):
            createTable()
        case let .CCDBTableActionUpgrade(updateTable):
            updateTable()
        case .CCDBTableActionNone:
            CCDBTableManager.shared.semphore.signal()
            return
        }
        CCDBTableManager.shared.semphore.signal()
    }
    
    func nextEditTableAction(typeName: String) {
        Self.nextEditTableAction(typeName: typeName)
    }
    
    static private func getNextTableAction(typeName: String) -> CCDBTableAction {
        if !checkTableInitialized(typeName: typeName) {
            CCDBTableManager.shared.dicTableInitialized[typeName] = true
            if CCDBConnection.needCreate {
                return CCDBTableAction.CCDBTableActionCreate(createTable)
            } else {
                return CCDBTableAction.CCDBTableActionUpgrade(updateTable)
            }
        }
        return CCDBTableAction.CCDBTableActionNone
    }
    
    static public func checkTableInitialized(typeName: String) -> Bool {
        guard let initialized = CCDBTableManager.shared.dicTableInitialized[typeName] else {
            return false
        }
        return initialized
    }
}
