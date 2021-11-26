//
//  CCDBInstancePool.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/12.
//

import Foundation
import SQLite3

public class CCDBInstance {
    var queue : DispatchQueue
    var instance : OpaquePointer?
    var dicStatments : [String : CCDBStatement] = Dictionary()
    
    init(queue: DispatchQueue, instance: OpaquePointer?) {
        self.queue = queue
        self.instance = instance
    }
}

class CCDBInstancePool {
    static let shared = CCDBInstancePool()
    
    static let DB_INSTANCE_POOL_SIZE = 4
    
    var index = 0
    
    var instances : [CCDBInstance] = []
    
    init() {
        
    }
    
    func getATransaction()->CCDBInstance {
        let instanceIndex = self.index % CCDBInstancePool.DB_INSTANCE_POOL_SIZE
        self.index = self.index + 1
        return self.instances[instanceIndex]
    }
    
    func addDBInstance(_ sqlite3Instance: OpaquePointer?) {
        let queue = dispatch_queue_serial_t.init(label: "CCDB_queue_\(self.index)")
        let dbInstance = CCDBInstance(
            queue: queue, instance: sqlite3Instance)
        self.instances.append(dbInstance)
        self.index = self.index + 1
    }
    
    func getTransaction(index: Int)->CCDBInstance {
        return self.instances[index]
    }
    
}
