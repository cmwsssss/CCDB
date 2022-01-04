//
//  CCModelSavingable.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/12.
//

import Foundation
import SQLite3

public enum CCModelAction {
    case CCModelActionInitWithPrimary((AnyHashable)->Any?, value:AnyHashable)
    case CCModelActionReplaceIntoDB(containerId: Int?, top: Bool)
    case CCModelActionQuery((CCDBCondition)->[Any], condition:CCDBCondition)
    case CCModelActionCount((CCDBCondition)->Int, condition:CCDBCondition)
    case CCModelActionRemove(containerId: Int?)
    case CCModelActionRemoveAll(containerId: Int?)
    case CCModelActionRemoveIndex(propertyName: String)
    case CCModelActionCreateIndex(propertyName: String)
}

/**
 Please inherit this protocol within the model that needs access to CCDB (请在需要接入CCDB的模型内继承该协议)
 
 ```
 class YourModel: CCModelSavingable {
 
    var id = "" //primary key
    ...
    static func modelConfiguration() -> CCModelConfiguration {
        var configuration = CCModelConfiguration(modelInit: YourModel.init)
        ...
        return configuration
    }
 }
 ```
 
 - **CCDB will identify the first attribute as the primary key attribute**
 - Please ensure that the init method of the current model is available
 - Please don't worry about the threaded calls to CCDB, any operation of CCDB will first operate the memory cache within the current thread, time consuming database operations will be handled by a dedicated thread so that it won't cause blocking to the API call threads.
 
 (
 - **CCDB将会将第一个属性识别为主键属性**
 - 请确保当前模型的init方法可以使用
 - 请不用担心CCDB的线程调用问题，CCDB的任何操作都会先在当前线程内操作内存缓存，耗时的数据库操作会由专门的线程进行处理，这样不会对API的调用线程造成阻塞
 
 )
 */
public protocol CCModelSavingable : CCModelCacheable, CCDBTransactionable, CCDBTableEditable {
    
    /**
     Configuration of the model (对模型进行配置)
     
     Every model that inherits CCModelSavingable needs to implement this method, please configure the model inside this method
     
     (每一个继承了CCModelSavingable的模型都需要实现该方法，请在该方法的内部对该模型进行配置)
     
     ```
     class UserModel: CCModelSavingable {
         var userId = ""
         @Published var username = ""
         @Published var height: OptionModel?
     }
     
     static func modelConfiguration() -> CCModelConfiguration {
         var configuration = CCModelConfiguration(modelInit: UserModel.init)
         configuration.publishedTypeMapper["_username"] = String.self
         configuration.inOutPropertiesMapper["_height"] = true
         configuration.intoDBMapper = intoDBMapper
         configuration.outDBMapper = outDBMapper
         return configuration
     }
     
     static func intoDBMapper(instance: Any)->String {
        return jsonString
     }
     
     static func outDBMapper(instance: Any, rawData: String) {
        //Parsing json strings
     }
     
     ```
     
     - returns: Instance of CCModelConfiguration (模型配置类的实例对象)
     */
    static func modelConfiguration() -> CCModelConfiguration
    
    /**
     Replace the object into the database (将当前对象写入数据库)
     */
    
    func replaceIntoDB()
    
    /**
     Replace the object into the database (将当前对象写入数据库, 并同时写入容器列表)
     - parameter containerId: The id of the container list (容器的Id号)

     - parameter top: Replace the object into the head/tail of the container list (将该对象放到容器列表的头部/尾部)
     */
    func replaceIntoDB(containerId: Int, top: Bool)
    
    /**
     Remove the object from the database and from the memory cache (将该对象从数据库内和内存缓存中移除)
     */
    func removeFromDB()
    
    /**
     Remove the object from the container list (将该对象从容器列表内移除)
     */
    func removeFromDB(containerId: Int)
    
    /**
     SwiftUI only, Notify the UI when the model changes for a refresh ( **SwiftUI专用** 当模型发生变化时，通知UI进行刷新)
     
     If the model inherits from the ObservableObject protocol, you will need to implement this method within the model if you wish to refresh the page after the model has performed a data operation
     
     (如果该模型继承了ObservableObject协议，如果你希望在模型进行数据操作后刷新页面，则需要在模型内实现该方法)
     ```
     class UserModel: CCModelSavingable, ObservableObject {
        ...
     
        func notiViewUpdate() {
            self.objectWillChange.send()
        }
     }
     
     ```
     */
    func notiViewUpdate()
    
    /**
     Query from the memory cache based on the value of the primary property (根据主键进行查询)
     
     - parameter value: The value of the primary property, can be AnyHashable (主键的值，类型为AnyHashable)
     
     - returns: Target object (查询到的模型对象)
     
     */
    static func initWithPrimaryPropertyValue(_ value: AnyHashable) -> Self?

    /**
     Get the number of data in the model table (获取当前模型表的数据数量)
     
     - returns: count (数据量)
     */
    static func count() -> Int
    
    /**
     Get the number of data that meet the current condition (获取满足当前条件下的数据的数量)
     
     - parameter condition: Conditions of the query (查询的条件)
     - returns: count (数据量)
     */
    static func count(_ condition: CCDBCondition) -> Int
    
    /**
     Get all the data of the model table (获取当前模型表的全部数据)
     
     - parameter isAsc: Sorting by rowid in reverse/ascending order (根据rowid进行倒序/升序进行排序)
     - returns: Instances of the model (该模型的实例对象)
     */
    static func queryAll(_ isAsc: Bool) -> [Self]
    
    /**
     Get all the data in the specified container list of the model (获取当前模型的指定容器列表内的全部数据)
     
     - parameter isAsc: Sorting by rowid in reverse/ascending order (根据rowid进行倒序/升序进行排序)
     - parameter containerId: The id of the container list (容器的Id号)
     - returns: Instances of the model (该模型的实例对象)
     */
    static func queryAll(_ isAsc: Bool, withContainerId containerId: Int) -> [Self]
    
    /**
     Query datas that meet the current condition (根据查询条件对模型表进行数据查询)
     
     - returns: Instances of the model (该模型的实例对象)
     */
    static func query(_ condition: CCDBCondition) -> [Self]
    
    /**
     Clear all data in this model table from the database and memory cache (从数据库和内存缓存中清除该模型表内的所有数据)
     */
    static func removeAll()
    
    /**
     Clear all data in the specified container from the database and memory cache (从数据库和内存缓存中清除指定容器内的所有数据)
     
     This method does not remove the original data of the object from the memory cache and the data table, it only removes it from the container list
     
     (该方法不会将对象的原始数据从内存缓存和数据表中移除，只会将其从容器列表内移除)
     
     - parameter containerId: The id of the container list (容器的Id号)
     */
    static func removeAll(containerId: Int)
    
    /**
     Create index of the specified property (对指定的属性建立索引)
     
     - parameter propertyName: (属性名，如果是@Published包装过的属性，则为_属性名)
     */
    static func createIndex(propertyName: String)
    
    /**
     Remove index of the specified property (删除指定的属性的索引)
     
     - parameter propertyName: (属性名，如果是@Published包装过的属性，则为_属性名)
     */
    static func removeIndex(propertyName: String)
        
    /**
     SwiftUI only, Notify the UI when the model changes for a refresh ( **SwiftUI专用** 当模型发生变化时，通知UI进行刷新)
     
     ```
     UserModel.addViewNotifier {
        //UI refreshing
     }
     ```
     */
    static func addViewNotifier(notifier: @escaping ()->Void)
    
        
}

public extension CCModelSavingable {
        
    static func performAction(action: CCModelAction) -> Any? {
        self.nextEditTableAction(typeName: Self.fastModelIndex())
        switch action {
        case let .CCModelActionInitWithPrimary(initWithPrimaryProperty, value):
            CCDBUpdateManager.shared.waitInit()
            return initWithPrimaryProperty(value)
        case let .CCModelActionQuery(query, condition: condition):
            CCDBUpdateManager.shared.waitInit()
            return query(condition)
        case let .CCModelActionCount(count, condition: condition):
            CCDBUpdateManager.shared.waitInit()
            return count(condition)            
        case let .CCModelActionCreateIndex(propertyName: propertyName):
            _createIndex(propertyName: propertyName)
        case let .CCModelActionRemoveIndex(propertyName: propertyName):
            _createIndex(propertyName: propertyName)
        default:
            break
        }
        return nil
    }
    
    func performAction(action: CCModelAction) -> Any? {
        self.nextEditTableAction(typeName: Self.fastModelIndex())
        switch action {
        case let .CCModelActionReplaceIntoDB(containerId: containerId, top: top):
            guard let propertyMapper = CCModelMapperManager.shared.getMapperWithTypeName(Self.fastModelIndex(), type: Self.self) else {
                return nil
            }
            CCModelNotifierManager.shared.sendViewUpdateNotify(type: Self.self)
        default:
            break
        }
        return nil
    }
    
    static internal func _initWithPrimaryPropertyValue(_ value: AnyHashable, needWait: Bool = true) -> Self? {
        
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return nil
        }
        
        if needWait {
            waitCacheChangeDone(mapper: mapper)
        }
            
        if let res = self.initWithPrimaryPropertyFromCache(value: value) as? Self {
            return res
        }
        
        guard let res = performAction(action: .CCModelActionInitWithPrimary(_initWithPrimaryPropertyValue, value: value)) as? Self else {
            return nil
        }
        res.replaceIntoCache()
        return res
    }
    
    static func initWithPrimaryPropertyValue(_ value: AnyHashable) -> Self? {
        return self._initWithPrimaryPropertyValue(value, needWait: true)
    }
    
    func insertMMAPCache(value: Any, columnType: CCDBColumnType, propertyName: String, index: Int, type: Any.Type = Any.self) -> CCModelSavingable? {
        switch columnType {
        case .CCDBColumnTypeBool:
            if let boolValue = value as? Bool {
                ccdb_insertMMAPCacheWithBool(boolValue, propertyName, index)
            } else {
                ccdb_insertMMAPCacheWithNull(propertyName, index)
            }
        case .CCDBColumnTypeInt:
            if let intValue = value as? Int {
                ccdb_insertMMAPCacheWithInt(intValue, propertyName, index)
            } else {
                ccdb_insertMMAPCacheWithNull(propertyName, index)
            }
        case .CCDBColumnTypeLong:
            if let intValue = value as? Int {
                ccdb_insertMMAPCacheWithInt(intValue, propertyName, index)
            } else {
                ccdb_insertMMAPCacheWithNull(propertyName, index)
            }
        case .CCDBColumnTypeString:
            if let stringValue = value as? String {
                ccdb_insertMMAPCacheWithString(stringValue, propertyName, index)
            } else {
                ccdb_insertMMAPCacheWithNull(propertyName, index)
            }
        case .CCDBColumnTypeDouble:
            if let doubleValue = value as? Double {
                ccdb_insertMMAPCacheWithDouble(doubleValue, propertyName, index)
            } else {
                ccdb_insertMMAPCacheWithNull(propertyName, index)
            }
        case .CCDBColumnTypeCustom:
            return replaceCustomValueIntoMMAPCache(value: value, type: type, mmapIndex: index, propertyName: propertyName)
        }
        return nil
    }
    
    func getPrimaryProperty(target:CCModelSavingable, mapper: CCModelPropertyMapper) -> PropertyInfo? {
        var instance = target
        let properties = mapper.properties
        let rawPointer = instance.headPointer()
        let primaryProperty = properties[0]
        
        let propAddr = rawPointer.advanced(by: primaryProperty.offset)
        let propertyDetail = PropertyInfo(key: primaryProperty.key, type: primaryProperty.type, address: propAddr, bridged: false)
        return propertyDetail
    }
    
    func getValue(propertyDetail: PropertyInfo, mapper: CCModelPropertyMapper) -> Any? {
        guard var value = extensions(of: propertyDetail.type).value(from: propertyDetail.address) else {
            return nil
        }
        
        if mapper.publishedTypeMapper[propertyDetail.key] != nil {
            if let currentValue = Self.findPublisherCurrentValue(value: value, finalLevel: false) {
                value = currentValue
            }
        }
        return value
    }
    
    func removeFromDB() {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper =
                CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self),
              let propertyDetail = getPrimaryProperty(target: self, mapper: mapper),
              let value = getValue(propertyDetail: propertyDetail, mapper: mapper),
              let columnType = mapper.columnType[propertyDetail.key]
        else {
            return
        }
        
        Self.waitCacheChangeDone(mapper: mapper)

        self.removeFromCache()
        
        ccdb_beginMMAPCacheTransaction(mapper.mmapIndex, CCDBMMAPTransactionType(2))
        insertMMAPCache(value: value, columnType: columnType, propertyName: propertyDetail.key, index: mapper.mmapIndex)
        ccdb_commitMMAPCacheTransaction(mapper.mmapIndex)
        
        ccdb_beginMMAPCacheTransaction(mapper.mmapIndex, CCDBMMAPTransactionType(7))
        insertMMAPCache(value: value, columnType: columnType, propertyName: "primary_key", index: mapper.mmapIndex)
        ccdb_commitMMAPCacheTransaction(mapper.mmapIndex)
    }
    
    func removeFromDB(containerId: Int) {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper =
                CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self),
              let propertyDetail = getPrimaryProperty(target: self, mapper: mapper),
              let value = getValue(propertyDetail: propertyDetail, mapper: mapper),
              let columnType = mapper.columnType[propertyDetail.key]
        else {
            return
        }
        
        Self.waitCacheChangeDone(mapper: mapper)
        
        self.removeFromCache(containerId: containerId)
        
        ccdb_beginMMAPCacheTransaction(mapper.mmapIndex, CCDBMMAPTransactionType(4))
        ccdb_insertMMAPCacheWithInt(containerId, "hash_id", mapper.mmapIndex)
        insertMMAPCache(value: value, columnType: columnType, propertyName: "primary_key", index: mapper.mmapIndex)
        ccdb_commitMMAPCacheTransaction(mapper.mmapIndex)
    }
    
    private func replaceCustomValueIntoMMAPCache(value: Any, type: Any.Type, mmapIndex: Int, propertyName: String) -> CCModelSavingable? {
        if let customValue = value as? CCModelSavingable,
           let propertyMapper = CCModelMapperManager.shared.getMapperWithType(type),
           let propertyDetail = getPrimaryProperty(target: customValue, mapper: propertyMapper),
           let value = getValue(propertyDetail: propertyDetail, mapper: propertyMapper),
           let columnType = propertyMapper.columnType[propertyDetail.key]
        {
            insertMMAPCache(value: value, columnType: columnType, propertyName: propertyName, index: mmapIndex, type: propertyDetail.type)
            return customValue
        } else {
            ccdb_insertMMAPCacheWithNull(propertyName, mmapIndex)
            return nil
        }
    }
    
    func replaceIntoDB(containerId: Int, top: Bool) {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper =
                CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self),
              let propertyDetail = getPrimaryProperty(target: self, mapper: mapper),
              let value = getValue(propertyDetail: propertyDetail, mapper: mapper),
              let columnType = mapper.columnType[propertyDetail.key]
        else {
            return
        }
        
        Self.waitCacheChangeDone(mapper: mapper)
        
        self.replaceIntoDB()
        
        self.replaceIntoCache(containerId: containerId, top: top)
        
        ccdb_beginMMAPCacheTransaction(mapper.mmapIndex, CCDBMMAPTransactionType(3))
        ccdb_insertMMAPCacheWithString("\(containerId)-\(value)", "id", mapper.mmapIndex)
        ccdb_insertMMAPCacheWithInt(containerId, "hash_id", mapper.mmapIndex)
        insertMMAPCache(value: value, columnType: columnType, propertyName: "primary_key", index: mapper.mmapIndex)
        if top {
            ccdb_insertMMAPCacheWithDouble(Date().timeIntervalSince1970, "update_time", mapper.mmapIndex)
        } else {
            ccdb_insertMMAPCacheWithDouble(-Date().timeIntervalSince1970, "update_time", mapper.mmapIndex)
        }
        ccdb_commitMMAPCacheTransaction(mapper.mmapIndex)
        
        self.performAction(action: .CCModelActionReplaceIntoDB(containerId: containerId, top: top))
    }
    
    func replaceIntoDB() {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return
        }
        
        Self.waitCacheChangeDone(mapper: mapper)

        self.replaceIntoCache()
        var instance = self
        let rawPointer = instance.headPointer()
        let properties = mapper.properties
        var customObjects = [CCModelSavingable]()
        
        ccdb_beginMMAPCacheTransaction(mapper.mmapIndex, CCDBMMAPTransactionType(1))
        for property in properties {
            if mapper.inOutPropertiesMapper[property.key] != nil {
                continue
            }

            let propAddr = rawPointer.advanced(by: property.offset)
            guard var value = extensions(of: property.type).value(from: propAddr) else {
                return
            }

            if mapper.publishedTypeMapper[property.key] != nil {
                if let currentValue = Self.findPublisherCurrentValue(value: value, finalLevel: false) {
                    value = currentValue
                }
            }
            guard let columnType = mapper.columnType[property.key] else {
                continue
            }
            if columnType == .CCDBColumnTypeCustom {
                var type = property.type
                if let realType = mapper.publishedTypeMapper[property.key] {
                    type = realType
                }
                if let customObject = insertMMAPCache(value: value, columnType: columnType, propertyName: property.key, index: mapper.mmapIndex, type: type) {
                    customObjects.append(customObject)
                }
            } else {
                insertMMAPCache(value: value, columnType: columnType, propertyName: property.key, index: mapper.mmapIndex)
            }
        }
        if let intoDBFunc = mapper.intoDBMapper {
            ccdb_insertMMAPCacheWithString(intoDBFunc(instance), "CUSTOM_INOUT_PROPERTIES", mapper.mmapIndex)
        } else {
            ccdb_insertMMAPCacheWithNull("CUSTOM_INOUT_PROPERTIES", mapper.mmapIndex)
        }
        ccdb_commitMMAPCacheTransaction(mapper.mmapIndex)
        
        for customObject in customObjects {
            customObject.replaceIntoDB()
        }
        
        self.performAction(action: .CCModelActionReplaceIntoDB(containerId: nil, top: true))
    }
        
    func notiViewUpdate() {
        
    }
        
    static func queryAll(_ isAsc: Bool = true) -> [Self] {
        
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return [Self]()
        }
        
        mapper.cacheChangeSemaphore.wait()
        if let res = self.loadAllFromCache(isAsc: isAsc), mapper.memoryCacheInited == true {
            mapper.cacheChangeSemaphore.signal()
            return res as! [Self]
        }
        let condition = CCDBCondition()
        condition.ccIsAsc(isAsc: isAsc)
        guard let res = performAction(action: .CCModelActionQuery(_query, condition: condition)) as? [Self] else {
            mapper.cacheChangeSemaphore.signal()
            return [Self]()
        }
        mapper.cacheChangeSemaphore.signal()
        
        mapper.cacheQueue.async {
            mapper.cacheChangeSemaphore.wait()
            for obj in res {
                obj.replaceIntoCache()
            }
            mapper.cacheChangeSemaphore.signal()
        }
        mapper.memoryCacheInited = true
        return res
    }
    
    static func queryAll(_ isAsc: Bool, withContainerId containerId: Int) -> [Self] {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return [Self]()
        }
        
        mapper.cacheChangeSemaphore.wait()
        if let res = self.loadAllFromCache(containerId: containerId, isAsc: isAsc), mapper.containerMemoryCacheInited[containerId] == true {
            mapper.cacheChangeSemaphore.signal()
            return res as! [Self]
        }
        let condition = CCDBCondition()
        condition.ccIsAsc(isAsc: isAsc).ccContainerId(containerId: containerId)
        guard let res = performAction(action: .CCModelActionQuery(_query, condition: condition)) as? [Self] else {
            mapper.cacheChangeSemaphore.signal()
            return [Self]()
        }
        mapper.cacheChangeSemaphore.signal()
        
        mapper.cacheQueue.async {
            mapper.cacheChangeSemaphore.wait()
            for obj in res {
                obj.replaceIntoCache(containerId: containerId, top: !isAsc)
            }
            mapper.cacheChangeSemaphore.signal()
        }
        mapper.containerMemoryCacheInited[containerId] = true;
        return res
    }
    
    static func query(_ condition: CCDBCondition) -> [Self] {
        CCDBUpdateManager.shared._replaceIntoDB()
        guard let res = performAction(action: .CCModelActionQuery(_query, condition: condition)) as? [Self] else {
            return [Self]()
        }
        return res
    }
    
    static func removeAll() {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return
        }
        
        waitCacheChangeDone(mapper: mapper)
        
        self.removeAllFromCache()
        
        ccdb_beginMMAPCacheTransaction(mapper.mmapIndex, CCDBMMAPTransactionType(5))
        ccdb_commitMMAPCacheTransaction(mapper.mmapIndex)
        
        ccdb_beginMMAPCacheTransaction(mapper.mmapIndex, CCDBMMAPTransactionType(8))
        ccdb_commitMMAPCacheTransaction(mapper.mmapIndex)
        
        performAction(action: .CCModelActionRemoveAll(containerId: nil))
    }
    
    static func removeAll(containerId: Int) {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return
        }
        
        waitCacheChangeDone(mapper: mapper)
        
        self.removeAllFromCache(containerId: containerId)
        
        ccdb_beginMMAPCacheTransaction(mapper.mmapIndex, CCDBMMAPTransactionType(6))
        ccdb_insertMMAPCacheWithInt(containerId, "hash_id", mapper.mmapIndex)
        ccdb_commitMMAPCacheTransaction(mapper.mmapIndex)
        
        performAction(action: .CCModelActionRemoveAll(containerId: containerId))
    }
    
    static internal func _count(needWait: Bool = true) -> Int {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return 0
        }
        
        CCDBUpdateManager.shared._replaceIntoDB()
        
        if needWait {
            waitCacheChangeDone(mapper: mapper)
        }

        guard let res = performAction(action: .CCModelActionCount(_count, condition: CCDBCondition())) as? Int else {
            return 0
        }
        return res
    }
    
    static func count() -> Int {
        return _count(needWait: true)
    }
    
    static internal func _count(_ condition: CCDBCondition, needWait:Bool = true) -> Int {
        let fastModelIndex = Self.fastModelIndex()
        guard let mapper = CCModelMapperManager.shared.getMapperWithTypeName(fastModelIndex, type: Self.self) else {
            return 0
        }
        
        CCDBUpdateManager.shared._replaceIntoDB()
        
        if needWait {
            waitCacheChangeDone(mapper: mapper)
        }
        
        guard let res = performAction(action: .CCModelActionCount(_count, condition: condition)) as? Int else {
            return 0
        }
        return res
    }
    
    static func count(_ condition: CCDBCondition) -> Int {
        return _count(condition, needWait: true)
    }
    
    static func createIndex(propertyName: String) {
        performAction(action: .CCModelActionCreateIndex(propertyName: propertyName))
    }
    
    static func removeIndex(propertyName: String) {
        performAction(action: .CCModelActionRemoveIndex(propertyName: propertyName))
    }
    
    static func addViewNotifier(notifier: @escaping ()->Void) {
        let propertyMapper = CCModelMapperManager.shared.getMapperWithTypeName(Self.fastModelIndex(), type: Self.self)
        propertyMapper?.viewNotifier.append(notifier)
    }
    
    
    
}
