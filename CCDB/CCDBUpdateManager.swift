import Foundation
import System

class CCDBUpdateModel {
    var model :CCModelSavingable?
    var top = true
    var containerId :Int?
}

class CCDBUpdateManager : CCDBTransactionable {
    
    static let shared = CCDBUpdateManager()
    
    var bufferLock = DispatchSemaphore.init(value: 1)
    var updateLock = DispatchSemaphore.init(value: 1)
    var modelBuffer = [Any]()
    var models = [Any]()
    var lastCheckTime = Date()
    var _gcdQueue: DispatchQueue?
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
    }
    
    func replaceIntoDB() {
        if self.lastCheckTime.timeIntervalSinceNow > -1 || self.modelBuffer.count == 0 {
            return
        }
        self.lastCheckTime = Date()
        self.gcdQueue.async {
            self.updateLock.wait()
            self.bufferLock.wait()
            self.models.append(contentsOf: self.modelBuffer)
            self.modelBuffer.removeAll()
            self.bufferLock.signal()
            let dbInstance = CCDBInstancePool.shared.getATransaction()
            dbInstance.queue.async {
                let date = Date()
                self.beginTransaction(dbInstance)
                print("begin: \(self.models.count)")
                for model in self.models {
                    if let updateModel = model as? CCDBUpdateModel {
                        updateModel.model?._replaceIntoDB(dbInstance: dbInstance, containerId: updateModel.containerId ?? 0, top: updateModel.top)
                    } else {
                        guard let waitingModel = model as? CCModelSavingable else {
                            continue
                        }
                        waitingModel._replaceIntoDB(dbInstance: dbInstance)
                    }
                }
                self.commitTransaction(dbInstance)
                print("end: \(date.timeIntervalSinceNow)")
                self.models.removeAll()
                self.updateLock.signal()
                self.replaceIntoDB()
            }
        }
    }
    
    func addModel(model: Any) {
        self.bufferLock.wait()
        self.modelBuffer.append(model)
        self.bufferLock.signal()
        self.replaceIntoDB()
    }
    
}
