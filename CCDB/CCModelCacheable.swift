//
//  CCModelCacheAble.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/9.
//

import Foundation

/**
key-value Memory cache (Key-value式的内存缓存)
 
 CCDB writes the model objects to the memory cache before the actual database operations are performed, this protocol can also be used separately (在进行实际的数据库操作之前，CCDB会先将模型对象写入内存缓存之中，该协议也可以单独使用)
*/
public protocol CCModelCacheable {
    
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
}

public extension CCModelCacheable {
    
    
    func replaceIntoCache() {
        let mirror:Mirror = Mirror(reflecting: self)
        let value = mirror.children[mirror.children.startIndex].value
        if let primaryValue = value as? AnyHashable {
            let typeName = String(describing: Self.self)
            CCModelCacheManager.shared.addObjectToCache(className: typeName, propertyPrimaryValue: primaryValue, object: self)
        }
    }
    
    
    static func loadAllFromCache(isAsc: Bool) -> [Any]? {
        return CCModelCacheManager.shared.getObjectsFromCache(className: String(describing: Self.self), isAsc: isAsc)
    }
    
    
    static func loadAllFromCache(containerId: Int, isAsc: Bool) -> [Any]? {
        return CCModelCacheManager.shared.getObjectsFromCache(className: String(describing: Self.self), containerId: containerId, isAsc: isAsc)
    }
    
    
    public static func initWithPrimaryPropertyFromCache(value : AnyHashable) -> Any? {
        return CCModelCacheManager.shared.getObject(className: String(describing: Self.self), propertyPrimaryValue: value)
    }
    
    func replaceIntoCache(containerId: Int, top: Bool) {
        let mirror:Mirror = Mirror(reflecting: self)
        let value = mirror.children[mirror.children.startIndex].value
        if let primaryValue = value as? AnyHashable {
            let typeName = String(describing: Self.self)
            CCModelCacheManager.shared.addObjectToCache(className: typeName, propertyPrimaryValue: primaryValue, object: self)
            CCModelCacheManager.shared.addObjectToContainer(className: typeName, propertyPrimaryValue: primaryValue, containerId: containerId, top: top)
        }
    }
    
    func removeFromCache() {
        CCModelCacheManager.shared.removeObjectFromCache(className: String(describing: Self.self), object: self)
    }
    
    func removeFromCache(containerId: Int) {
        let mirror:Mirror = Mirror(reflecting: self)
        let value = mirror.children[mirror.children.startIndex].value
        if let primaryValue = value as? AnyHashable {
            CCModelCacheManager.shared.removeObjectFromContainerCache(className: String(describing: Self.self), propertyPrimaryValue: primaryValue, containerId: containerId)
        }
    }
    
    static func removeAllFromCache() {
        CCModelCacheManager.shared.removeAllFromCache(className: String(describing: Self.self))
    }
    
    static func removeAllFromCache(containerId: Int) {
        CCModelCacheManager.shared.removeAllFromCache(className: String(describing: Self.self), containerId: containerId)
    }
}
