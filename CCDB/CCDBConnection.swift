//
//  CCDBConnection.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/13.
//

import Foundation
import SQLite3
public class CCDBConnection {
    
    static var needUpgrade = false
    static var needCreate = true
    
    static var dbDocumentPath: String? {
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        if let dbDocumentPath = documentPath?.appending("/CCDB_data/") {
            if !FileManager.default.fileExists(atPath: dbDocumentPath, isDirectory: nil) {
                do {
                    try FileManager.default.createDirectory(atPath: dbDocumentPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    return nil
                }
            }
            return dbDocumentPath
        } else {
            return nil
        }
    }
    
    /**
     (初始化CCDB)
     
     Please call this method before using the CCDB API. This method will determine whether to update the database based on the version, and when your data model changes, then the value of the version will need to be changed
     
     (请在使用CCDB的API之前调用该方法，该方法会根据version来决定是否要更新数据库，当你的数据模型发生变更时，则需要修改version的值)
     
     - parameter version: Current version of the database (当前数据库的版本号)
     */
    
    public static func initializeDBWithVersion(_ version: String) {
        let dbFileName = "ccdb-" + version + ".db"
        let dbWalFile = "ccdb-" + version + ".db-wal"
        let dbShmFile = "ccdb-" + version + ".db-shm"
        guard let dbDocumentPath = self.dbDocumentPath else {
            return
        }
        let filePath = dbDocumentPath.appending(dbFileName)
        let dbWalFilePath = dbDocumentPath.appending(dbWalFile)
        let dbShmFilePath = dbDocumentPath.appending(dbShmFile)
        if !FileManager.default.fileExists(atPath: filePath) {
            if let files = FileManager.default.subpaths(atPath: dbDocumentPath) {
                for file in files {
                    if file.contains("ccdb-") {
                        self.needUpgrade = true
                        self.needCreate = false
                        do {
                            if file.contains("db-shm") {
                                try FileManager.default.moveItem(atPath: dbDocumentPath.appending(file), toPath: dbShmFilePath)
                            } else if file.contains("db-wal") {
                                try FileManager.default.moveItem(atPath: dbDocumentPath.appending(file), toPath: dbWalFilePath)
                            } else {
                                try FileManager.default.moveItem(atPath: dbDocumentPath.appending(file), toPath: filePath)
                            }
                        } catch  {
                            
                        }
                    }
                }
            }
        }
        print(filePath)
        for _ in 0...CCDBInstancePool.DB_INSTANCE_POOL_SIZE {
            CCDBInstancePool.shared.addDBInstance(openDatabase(filePath))
        }
    }
    
    static func openDatabase(_ filePath: String) -> OpaquePointer? {
        
        var instance: OpaquePointer?
        if sqlite3_open_v2(filePath.cString(using: String.Encoding.utf8), &instance, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_NOMUTEX, nil) != SQLITE_OK {
            sqlite3_close(instance)
            return nil
        }
        
        sqlite3_exec(instance, "PRAGMA journal_mode=WAL;".cString(using: String.Encoding.utf8), nil, nil, nil);
        sqlite3_exec(instance, "PRAGMA wal_autocheckpoint=100;".cString(using: String.Encoding.utf8), nil, nil, nil);
        return instance
    }
    
    static func statementWithSql(_ sql: String, instance:CCDBInstance) -> CCDBStatement {
        if let stmt = instance.dicStatments[sql] {
            return stmt
        } else {
            let stmt = CCDBStatement.init(withDBInstance: instance.instance, withSql: sql)
            instance.dicStatments[sql] = stmt
            return stmt
        }
    }
}
