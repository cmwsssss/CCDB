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
    
    func sendViewUpdateNotify(type: Any.Type) {
        self.needNotifyType.append(type)
        if self.status == .none {
            self.status = .wait
        } else {
            self.status = .needNext
        }
        self._sendViewUpdateNotify()
    }
    
    func _sendViewUpdateNotify() {
        if self.status == .wait {
            self.status = .notifing
            DispatchQueue.main.async {
                for notiType in self.needNotifyType {
                    if let propertyMapper = CCModelMapperManager.shared.getMapperWithType(notiType) {
                        for notifier in propertyMapper.needNotifierObject {
                            notifier.notiViewUpdate()
                        }
                        for notifier in propertyMapper.viewNotifier {
                            notifier()
                        }
                        for notifier in propertyMapper.needNotifierViews {
                            notifier.objectWillChange.send()
                        }
                    }
                }
                self.needNotifyType.removeAll()
                if self.status == .needNext {
                    self.status = .wait
                    self._sendViewUpdateNotify()
                } else {
                    self.status = .none
                }
            }
        }
    }
}
