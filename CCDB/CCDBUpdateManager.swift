import Foundation
import System

class CCDBUpdateModel {
    var model :CCModelSavingable?
    var top = true
    var containerId :Int?
}

class CCDBUpdateManager : CCDBTransactionable {
    
    static let shared = CCDBUpdateManager()
    
    var datas = [Any]()
    var inited = false
    var lastCheckTime = Date()
    var _gcdQueue: DispatchQueue?
    var initSemp = DispatchSemaphore(value: 1)
    var timer: DispatchSourceTimer?
    var gcdQueue: DispatchQueue {
        guard let queue = _gcdQueue else {
            _gcdQueue = dispatch_queue_serial_t.init(label: "update_queue")
            return _gcdQueue!
        }
        return queue
    }
    
    init() {
        self.timer = DispatchSource.makeTimerSource(flags: [], queue: _gcdQueue)
        self.timer?.schedule(deadline: .now(), repeating: 1)
        self.timer?.setEventHandler(handler: {
            self.replaceIntoDB()
        })
        self.timer?.resume()
        self._replaceIntoDB()
    }
    
    func waitInit() {
        self.initSemp.wait()
        self.initSemp.signal()
    }
    
    func _replaceIntoDB() {
        let dbInstance = CCDBInstancePool.shared.getATransaction()
        dbInstance.queue.sync {
            let date = Date()
            if !self.inited {
                self.initSemp.wait()
            }
            self.beginTransaction(dbInstance)
            ccdb_replaceMMAPCacheDataIntoDB(dbInstance.instance, dbInstance.index)
            if !self.inited {
                self.initSemp.signal()
                self.inited = true
            }
            self.commitTransaction(dbInstance)
            #if DEBUG
            print("Replace into DB time \(date.timeIntervalSinceNow)")
            #endif
            self.replaceIntoDB()
        }
    }
    
    func replaceIntoDB() {
        if self.lastCheckTime.timeIntervalSinceNow > -1 || (ccdb_cpuUsage() > 30 && self.lastCheckTime.timeIntervalSinceNow < -10) {
            return
        }
        self.lastCheckTime = Date()
        self.gcdQueue.async {
            self._replaceIntoDB()
        }
    }
    
}
