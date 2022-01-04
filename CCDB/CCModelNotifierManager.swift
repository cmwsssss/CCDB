//
//  CCModelNotifierManager.swift
//  CCModelExample
//
//  Created by cmw on 2021/11/19.
//

import Foundation
class CCModelNotifierManager {
    
    enum NotifyStatus {
        case none
        case wait
        case notifing
        case needNext
    }
    
    static let shared = CCModelNotifierManager()
    var needNotifyType = [Any.Type]()
    var waitNotify = false
    var notifing = false
    var status = NotifyStatus.none
    var sem = DispatchSemaphore(value: 1)
    
    func sendViewUpdateNotify(type: Any.Type) {
        self.sem.wait()
        self.needNotifyType.append(type)
        if self.status == .none {
            self.status = .wait
        } else {
            self.status = .needNext
        }
        self.sem.signal()
        self._sendViewUpdateNotify()
    }
    
    func _sendViewUpdateNotify() {
        if self.status == .wait {
            self.status = .notifing
            DispatchQueue.main.async {
                self.sem.wait()
                for notiType in self.needNotifyType {
                    if let ccType = notiType as? CCModelSavingable.Type, let propertyMapper = CCModelMapperManager.shared.getMapperWithTypeName(ccType.fastModelIndex(), type: ccType) {
                        for notifier in propertyMapper.needNotifierObject {
                            notifier.notiViewUpdate()
                        }
                        for notifier in propertyMapper.viewNotifier {
                            notifier()
                        }
                    }
                }
                self.needNotifyType.removeAll()
                if self.status == .needNext {
                    self.status = .wait
                    self.sem.signal()
                    self._sendViewUpdateNotify()
                } else {
                    self.status = .none
                    self.sem.signal()
                }
            }
        }
    }
}
