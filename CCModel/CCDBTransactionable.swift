//
//  CCDBTransaction.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/13.
//

import Foundation
import SQLite3

protocol CCDBTransactionable {
    func beginTransaction(_ instance : CCDBInstance)
    func commitTransaction(_ instance : CCDBInstance)
    func rollbackTransaction(_ instance : CCDBInstance)

}

extension CCDBTransactionable {
    
    func beginTransaction(_ instance : CCDBInstance) {
        let csql = "BEGIN".cString(using: String.Encoding.utf8)
        sqlite3_exec(instance.instance, csql, nil, nil, nil)
    }
    
    func commitTransaction(_ instance : CCDBInstance) {
        let csql = "COMMIT".cString(using: String.Encoding.utf8)
        sqlite3_exec(instance.instance, csql, nil, nil, nil)
    }
    
    func rollbackTransaction(_ instance : CCDBInstance) {
        let csql = "ROLLBACK".cString(using: String.Encoding.utf8)
        sqlite3_exec(instance.instance, csql, nil, nil, nil)
    }
}
