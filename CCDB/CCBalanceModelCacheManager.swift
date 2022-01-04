//
//  CCModelCacheManager.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/9.
//

import Foundation

class CCBalanceModelContainerCacheWrapper {
    var rawData = [AnyHashable: (TimeInterval, Any)]()
}

class CCBalanceModelCacheWrapper {
    var rawData = [AnyHashable: Any]()
    var containerCache: [Int : CCBalanceModelContainerCacheWrapper] = Dictionary()
}

class CCBalanceModelCacheManager {
    
    static let shared = CCBalanceModelCacheManager()
    
    var memoryCache : [String : CCBalanceModelCacheWrapper] = Dictionary()
        
    private init() {}
    
    public func addObjectToCache(className : String, propertyPrimaryValue: AnyHashable, object: Any) {
        ccdb_writeLock()
        let cache = self.memoryCache[className] ?? CCBalanceModelCacheWrapper()
        if self.memoryCache[className] == nil {
            self.memoryCache[className] = cache
        }
        if cache.rawData[propertyPrimaryValue] == nil {
            cache.rawData[propertyPrimaryValue] = object
        }
        ccdb_unlock()
    }
    
    
    public func addObjectToContainer(className: String, propertyPrimaryValue: AnyHashable, containerId: Int, top: Bool, object: Any) {
        ccdb_writeLock()
        let cache = self.memoryCache[className] ?? CCBalanceModelCacheWrapper()
        if self.memoryCache[className] == nil {
            self.memoryCache[className] = cache
        }
        let containerCache = cache.containerCache[containerId] ?? CCBalanceModelContainerCacheWrapper()
        if cache.containerCache[containerId] == nil {
            cache.containerCache[containerId] = containerCache
        }
        
        containerCache.rawData[propertyPrimaryValue] = (Date().timeIntervalSince1970,object)
        ccdb_unlock()
    }
        
    public func removeObjectFromCache(className: String, propertyPrimaryValue: AnyHashable) {
        ccdb_writeLock()
        guard let cache = self.memoryCache[className] else {
            ccdb_unlock()
            return
        }
        cache.rawData.removeValue(forKey: propertyPrimaryValue)
        ccdb_unlock()
        for containerCache in cache.containerCache.keys {
            self.removeObjectFromContainerCache(className: className, propertyPrimaryValue: propertyPrimaryValue, containerId: containerCache)
        }
    }
    
    public func removeObjectFromContainerCache(className: String, propertyPrimaryValue: AnyHashable, containerId: Int) {
        ccdb_writeLock()
        guard let cache = self.memoryCache[className], let containerCache = cache.containerCache[containerId] else {
            ccdb_unlock()
            return
        }
        
        containerCache.rawData.removeValue(forKey: propertyPrimaryValue)
        ccdb_unlock()
    }
    
    public func getObjectsFromCache(className: String, isAsc: Bool) -> [Any]? {
        guard let cache = self.memoryCache[className] else {
            return nil
        }
        ccdb_readLock()
        let values : [Any] = Array(cache.rawData.values)
        ccdb_unlock()
        return values
    }
    
    public func getObjectsFromCache(className: String, containerId: Int, isAsc: Bool) -> [Any]? {
        guard let cache = self.memoryCache[className], let containerCache = cache.containerCache[containerId] else {
            return nil
        }
        ccdb_readLock()
        let res = containerCache.rawData.values.sorted { data1, data2 in
            return (isAsc) ? data1.0 > data2.0 : data1.0 < data2.0
        }.map { data in
            return data.1
        }
        ccdb_unlock()
        return res
    }
    
    
    public func getObject(className : String, propertyPrimaryValue : AnyHashable) -> Any? {
        ccdb_readLock()
        guard let cache = self.memoryCache[className] else {
            ccdb_unlock()
            return nil
        }
        let res = cache.rawData[propertyPrimaryValue]
        ccdb_unlock()
        return res
    }
    
    public func removeAllFromCache(className: String) {
        ccdb_writeLock()
        guard let cache = self.memoryCache[className] else {
            ccdb_unlock()
            return
        }
        cache.rawData.removeAll()
        cache.containerCache.removeAll()
        ccdb_unlock()
    }
    
    public func removeAllFromCache(className: String, containerId: Int) {
        ccdb_writeLock()
        guard let cache = self.memoryCache[className] else {
            ccdb_unlock()
            return
        }
        cache.containerCache[containerId]?.rawData.removeAll()
        ccdb_unlock()
    }
}
