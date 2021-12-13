//
//  RealmHelper.swift
//  CCModelExample
//
//  Created by cmw on 2021/11/19.
//

import Foundation
import Realm
import RealmSwift
class RealmHelper {
    public class func configRealm() {
            /// 这个方法主要用于数据模型属性增加或删除时的数据迁移，每次模型属性变化时，将 dbVersion 加 1 即可，Realm 会自行检测新增和需要移除的属性，然后自动更新硬盘上的数据库架构，移除属性的数据将会被删除。
        let dbVersion : UInt64 = 1
        let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as String
        let dbPath = docPath.appending("/defaultDB.realm")
        let config = Realm.Configuration(fileURL: URL.init(string: dbPath), inMemoryIdentifier: nil, syncConfiguration: nil, encryptionKey: nil, readOnly: false, schemaVersion: dbVersion, migrationBlock: { (migration, oldSchemaVersion) in
            
        }, deleteRealmIfMigrationNeeded: false, shouldCompactOnLaunch: nil, objectTypes: nil)
        Realm.Configuration.defaultConfiguration = config
        Realm.asyncOpen()
    }
    
    public class func getDB() -> Realm {
        let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as String
        let dbPath = docPath.appending("/defaultDB.realm")
        /// 传入路径会自动创建数据库
        let defaultRealm = try! Realm(fileURL: URL.init(string: dbPath)!)
        print("数据库地址->\(defaultRealm.configuration.fileURL?.absoluteString ?? "")")
        return defaultRealm
    }
    
    public class func addObject<T>(object: T){
        
        do {
            let defaultRealm = self.getDB()
            try defaultRealm.write {
                defaultRealm.add(object as! Object)
            }
            print(defaultRealm.configuration.fileURL ?? "")
        } catch {}
        
    }
}
