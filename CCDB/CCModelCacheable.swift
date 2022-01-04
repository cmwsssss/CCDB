//
//  CCModelCacheAble.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/9.
//

import Foundation

public enum CCModelCachePolicy {
    case fastQueryAndUpdate
    case balance
}

/**
key-value Memory cache (Key-value式的内存缓存)
 
 CCDB writes the model objects to the memory cache before the actual database operations are performed, this protocol can also be used separately (在进行实际的数据库操作之前，CCDB会先将模型对象写入内存缓存之中，该协议也可以单独使用)
*/
public protocol CCModelCacheable: _Measurable {
    
    /**
     Replace object into memory cache (将当前模型对象写入内存缓存)
    */
    func replaceIntoCache()
    
    /**
     Query from the memory cache based on the value of the primary property (根据主键进行查询)
     
     - parameter value: The value of the primary property, can be AnyHashable (主键的值，类型为AnyHashable)
     
     - returns: Target object (查询到的模型对象)
     
     */
    static func initWithPrimaryPropertyFromCache(value : AnyHashable) -> Any?
    
    /**
     Load all the datas in the model's cache pool (读取该模型的缓存池内的所有对象)
     
     - parameter isAsc: sort by updatedTime (根据写入时间升序/倒序返回结果)
     
     - returns: The model's objects (该模型的实例对象)
     
     */
    static func loadAllFromCache(isAsc: Bool) -> [Any]?
    
    /**
     Load all the datas in the model's container list (读取该模型指定容器内的对象)
     
     - parameter containerId: The id of the container list (容器的Id号)

     - parameter isAsc: sort by updatedTime (根据写入时间升序/倒序返回结果)
     
     - returns: The model's objects (该模型的实例对象)
     
     */
    static func loadAllFromCache(containerId: Int, isAsc: Bool) -> [Any]?
        
    /**
     replce object into the memory cache (将当前对象写入内存缓存中)
     
     - parameter containerId: The id of the container list (容器的Id号)

     - parameter top: Replace the object into the head/tail of the container list (将该对象放到容器列表的头部/尾部)
     */
    func replaceIntoCache(containerId: Int, top: Bool)
    
    /**
     Remove the object from the memory cache (将当前对象从内存缓存中移除)
     */
    func removeFromCache()
    
    /**
     Remove the object from the container list (将当前对象从容器列表中移除)
     
     This method does not remove the object from the memory cache, it only removes it from the container list (该方法不会将当前对象从内存缓存中移除，只会将其从容器列表内移除)
     
     - parameter containerId: The id of the container list (容器的Id号)
     
     */
    func removeFromCache(containerId: Int)
            
    
    /**
     Empty all memory caches of this model (将该模型下的所有内存缓存清空)
     */
    static func removeAllFromCache()
    
    /**
     Empty all memory caches of this container (将该容器列表下的数据清空)
     
     This method does not remove the object from the memory cache, it only removes it from the container list  (该方法不会将数据从内存缓存中移除，只会将其从容器列表内移除)
     
     - parameter containerId: The id of the container list (容器的Id号)
     
     */
    static func removeAllFromCache(containerId: Int)
    
    static func fastModelIndex() -> String

}

public extension CCModelCacheable {
    
    func replaceIntoCache() {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return
        }

        var instance = self
        let rawPointer = instance.headPointer()
        let properties = mapper.properties
        if let property = properties.first {

            let propAddr = rawPointer.advanced(by: property.offset)
            guard var value = extensions(of: property.type).value(from: propAddr) else {
                return
            }

            if mapper.publishedTypeMapper[property.key] != nil {
                if let currentValue = Self.findPublisherCurrentValue(value: value, finalLevel: false) {
                    value = currentValue
                }
            }
            
            if let primaryValue = value as? AnyHashable {
                if mapper.cachePolicy == .fastQueryAndUpdate {
                    CCModelCacheManager.shared.addObjectToCache(className: fastModelIndex, propertyPrimaryValue: primaryValue, object: self)
                } else {
                    CCBalanceModelCacheManager.shared.addObjectToCache(className: fastModelIndex, propertyPrimaryValue: primaryValue, object: self)
                }
            }
        }
    }
    
    
    static func loadAllFromCache(isAsc: Bool = true) -> [Any]? {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return nil
        }
        if mapper.cachePolicy == .fastQueryAndUpdate {
            return CCModelCacheManager.shared.getObjectsFromCache(className: Self.fastModelIndex(), isAsc: isAsc)
        } else {
            return CCBalanceModelCacheManager.shared.getObjectsFromCache(className: Self.fastModelIndex(), isAsc: isAsc)
        }
    }
    
    
    static func loadAllFromCache(containerId: Int, isAsc: Bool) -> [Any]? {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return nil
        }
        if mapper.cachePolicy == .fastQueryAndUpdate {
            return CCModelCacheManager.shared.getObjectsFromCache(className: Self.fastModelIndex(), containerId: containerId, isAsc: isAsc)
        } else {
            return CCBalanceModelCacheManager.shared.getObjectsFromCache(className: Self.fastModelIndex(), containerId: containerId, isAsc: isAsc)
        }
    }
    
    
    public static func initWithPrimaryPropertyFromCache(value : AnyHashable) -> Any? {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return nil
        }
        if mapper.cachePolicy == .fastQueryAndUpdate {
            return CCModelCacheManager.shared.getObject(className: Self.fastModelIndex(), propertyPrimaryValue: value)
        } else {
            return CCBalanceModelCacheManager.shared.getObject(className: Self.fastModelIndex(), propertyPrimaryValue: value)
        }
    }
    
    func replaceIntoCache(containerId: Int, top: Bool) {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return
        }

        var instance = self
        let rawPointer = instance.headPointer()
        let properties = mapper.properties
        if let property = properties.first {

            let propAddr = rawPointer.advanced(by: property.offset)
            guard var value = extensions(of: property.type).value(from: propAddr) else {
                return
            }

            if mapper.publishedTypeMapper[property.key] != nil {
                if let currentValue = Self.findPublisherCurrentValue(value: value, finalLevel: false) {
                    value = currentValue
                }
            }
            
            if let primaryValue = value as? AnyHashable {
                if mapper.cachePolicy == .fastQueryAndUpdate {
                    CCModelCacheManager.shared.addObjectToCache(className: fastModelIndex, propertyPrimaryValue: primaryValue, object: self)
                    CCModelCacheManager.shared.addObjectToContainer(className: fastModelIndex, propertyPrimaryValue: primaryValue, containerId: containerId, top: top)
                } else {
                    CCBalanceModelCacheManager.shared.addObjectToCache(className: fastModelIndex, propertyPrimaryValue: primaryValue, object: self)
                    CCBalanceModelCacheManager.shared.addObjectToContainer(className: fastModelIndex, propertyPrimaryValue: primaryValue, containerId: containerId, top: top, object: self)
                }
            }
        }
    }
    
    func removeFromCache() {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return
        }
        let mirror:Mirror = Mirror(reflecting: self)
        let value = mirror.children[mirror.children.startIndex].value
        if let primaryValue = value as? AnyHashable {
            if mapper.cachePolicy == .fastQueryAndUpdate {
                CCModelCacheManager.shared.removeObjectFromCache(className: Self.fastModelIndex(), object: primaryValue)
            } else {
                CCBalanceModelCacheManager.shared.removeObjectFromCache(className: Self.fastModelIndex(), propertyPrimaryValue: primaryValue)
            }
        }
    }
    
    func removeFromCache(containerId: Int) {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return
        }
        let mirror:Mirror = Mirror(reflecting: self)
        let value = mirror.children[mirror.children.startIndex].value
        if let primaryValue = value as? AnyHashable {
            if mapper.cachePolicy == .fastQueryAndUpdate {
                CCModelCacheManager.shared.removeObjectFromContainerCache(className: Self.fastModelIndex(), propertyPrimaryValue: primaryValue, containerId: containerId)
            } else {
                CCBalanceModelCacheManager.shared.removeObjectFromContainerCache(className: Self.fastModelIndex(), propertyPrimaryValue: primaryValue, containerId: containerId)
            }
        }
    }
    
    static func removeAllFromCache() {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return
        }
        if mapper.cachePolicy == .fastQueryAndUpdate {
            CCModelCacheManager.shared.removeAllFromCache(className: Self.fastModelIndex())
        } else {
            CCBalanceModelCacheManager.shared.removeAllFromCache(className: Self.fastModelIndex())
        }
    }
    
    static func removeAllFromCache(containerId: Int) {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return
        }
        if mapper.cachePolicy == .fastQueryAndUpdate {
            CCModelCacheManager.shared.removeAllFromCache(className: Self.fastModelIndex(), containerId: containerId)
        } else {
            CCBalanceModelCacheManager.shared.removeAllFromCache(className: Self.fastModelIndex(), containerId: containerId)
        }
    }
    
    static func fastModelIndex() -> String {
        return String(describing: Self.self)
    }
    
    static func waitCacheChangeDone(mapper: CCModelPropertyMapper) {
        mapper.cacheChangeSemaphore.wait()
        mapper.cacheChangeSemaphore.signal()
    }
    
}

extension CCModelCacheable {
    
    static func findPublisherCurrentValue(value: Any, finalLevel: Bool) -> Any? {
        let mirror = Mirror(reflecting: value)
        if finalLevel {
            for child in mirror.children {
                if child.label == "currentValue" || child.label == "value" {
                    return child.value
                }
            }
        } else {
            for child in mirror.children {
                if child.label == "currentValue" || child.label == "value" {
                    return child.value
                }
                else {
                    if child.label == "subject" {
                        if let finalValue = findPublisherCurrentValue(value: child.value, finalLevel: true) {
                            return finalValue
                        }
                    } else {
                        if let finalValue = findPublisherCurrentValue(value: child.value, finalLevel: false) {
                            return finalValue
                        }
                    }
                }
            }
        }
        return nil
    }
}
