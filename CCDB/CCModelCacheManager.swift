//
//  CCModelCacheManager.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/9.
//

import Foundation

class CCModelContainerCacheWrapper {
    var headCache: [AnyHashable] = Array()
    var tailCache: [AnyHashable] = Array()
    var sortIndex: [Bool] = Array()
}

class CCModelCacheWrapper {
    
    var cache : [Any] = Array()
    var rawData: [AnyHashable: Any] = Dictionary()
    var containerCache: [Int : CCModelContainerCacheWrapper] = Dictionary()
}

class CCModelCacheManager {
    
    static let shared = CCModelCacheManager()
    
    var memoryCache : [String : CCModelCacheWrapper] = Dictionary()
    
    var memoryCacheSem = DispatchSemaphore(value: 1)
    
    var replaceQueue = DispatchQueue(label: "CCDB_replaceQueue")
    
    private init() {}
    
    public func addObjectToCache(className : String, propertyPrimaryValue: AnyHashable, object : Any) {
        self.memoryCacheSem.wait()
        let cache = self.memoryCache[className] ?? CCModelCacheWrapper()
        if self.memoryCache[className] == nil {
            self.memoryCache[className] = cache
        }
        cache.cache.append(object)
        cache.rawData[propertyPrimaryValue] = object
        self.memoryCacheSem.signal()
    }
    
    
    public func addObjectToContainer(className: String, propertyPrimaryValue: AnyHashable, containerId: Int, top: Bool) {
        self.memoryCacheSem.wait()
        let cache = self.memoryCache[className] ?? CCModelCacheWrapper()
        if self.memoryCache[className] == nil {
            self.memoryCache[className] = cache
        }
        let containerCache = cache.containerCache[containerId] ?? CCModelContainerCacheWrapper()
        if cache.containerCache[containerId] == nil {
            cache.containerCache[containerId] = containerCache
        }
        containerCache.sortIndex.append(top)
        if top {
            containerCache.headCache.append(propertyPrimaryValue)
        } else {
            containerCache.tailCache.append(propertyPrimaryValue)
        }
        self.memoryCacheSem.signal()
    }
        
    public func removeObjectFromCache(className: String, object: Any) {
        self.memoryCacheSem.wait()
        guard let cache = self.memoryCache[className] else {
            self.memoryCacheSem.signal()
            return
        }
        let mirror:Mirror = Mirror(reflecting: self)
        let value = mirror.children[mirror.children.startIndex].value
        if let targetValue = value as? AnyHashable {
            cache.cache.removeAll(where: { cachedObject in
                let mirror:Mirror = Mirror(reflecting: cachedObject)
                let value = mirror.children[mirror.children.startIndex].value
                if let primaryValue = value as? AnyHashable, primaryValue == targetValue {
                    return true
                } else {
                    return false
                }
            })
        }
        
        self.memoryCacheSem.signal()
    }
    
    public func removeObjectFromContainerCache(className: String, propertyPrimaryValue: AnyHashable, containerId: Int) {
        self.memoryCacheSem.wait()
        guard let cache = self.memoryCache[className] else {
            self.memoryCacheSem.signal()
            return
        }
        guard let containerCache = cache.containerCache[containerId] else {
            self.memoryCacheSem.signal()
            return
        }
        containerCache.headCache.removeAll { value in
            value == propertyPrimaryValue
        }
        containerCache.tailCache.removeAll { value in
            value == propertyPrimaryValue
        }
        self.memoryCacheSem.signal()
    }
    
    public func getObjectsFromCache(className: String, isAsc: Bool) -> [Any]? {
        guard let cache = self.memoryCache[className] else {
            return nil
        }
        let date = Date()
        let datas = (isAsc) ? cache.cache : cache.cache.reversed()
        return datas
    }
    
    public func getObjectsFromCache(className: String, containerId: Int, isAsc: Bool) -> [Any]? {
        self.memoryCacheSem.wait()
        guard let cache = self.memoryCache[className] else {
            self.memoryCacheSem.signal()
            return nil
        }
        guard let containerCache = cache.containerCache[containerId] else {
            self.memoryCacheSem.signal()
            return nil
        }
        let date = Date()
        var res = [Any]()
        var exsited = [AnyHashable: Bool]()
        var head = 0
        var tail = 0
        let sortIndex = (isAsc) ? containerCache.sortIndex : containerCache.sortIndex.reversed()
        let headCache = (isAsc) ? containerCache.headCache : containerCache.headCache.reversed()
        let tailCache = (isAsc) ? containerCache.tailCache : containerCache.tailCache.reversed()
        for fromTop in sortIndex {
            var primaryValue: AnyHashable
            if fromTop {
                primaryValue = headCache[head]
                head = head + 1
            } else {
                primaryValue = tailCache[tail]
                tail = tail + 1
            }
            guard exsited[primaryValue] == nil else {
                continue
            }
            exsited[primaryValue] = true
            guard let data = cache.rawData[primaryValue] else {
                continue
            }
            res.append(data)
        }
        print("sorted: \(date.timeIntervalSinceNow)" )
        self.memoryCacheSem.signal()
        return res
    }
    
    
    public func getObject(className : String, propertyPrimaryValue : AnyHashable) -> Any? {
        self.memoryCacheSem.wait()
        guard let cache = self.memoryCache[className] else {
            self.memoryCacheSem.signal()
            return nil
        }
        let res = cache.rawData[propertyPrimaryValue]
        self.memoryCacheSem.signal()
        return res
    }
    
    public func removeAllFromCache(className: String) {
        self.memoryCacheSem.wait()
        guard let cache = self.memoryCache[className] else {
            self.memoryCacheSem.signal()
            return
        }
        cache.cache.removeAll()
        cache.containerCache.removeAll()
        self.memoryCacheSem.signal()
    }
    
    public func removeAllFromCache(className: String, containerId: Int) {
        self.memoryCacheSem.wait()
        guard let cache = self.memoryCache[className] else {
            self.memoryCacheSem.signal()
            return
        }
        cache.containerCache[containerId]?.sortIndex.removeAll()
        cache.containerCache[containerId]?.headCache.removeAll()
        cache.containerCache[containerId]?.tailCache.removeAll()
        self.memoryCacheSem.signal()
    }
}
