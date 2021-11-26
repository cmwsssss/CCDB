//
//  CCModelSavingable.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/12.
//

import Foundation
import SQLite3

enum CCModelAction {
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
protocol CCModelSavingable : CCModelCacheable, CCDBTransactionable, CCDBTableEditable, _Measurable {
    
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
    
    static func addViewNotifier(notifier: CCViewModel)
    
    static func removeViewNotifier(notifier: CCViewModel)
    
    
}

extension CCModelSavingable {
        
    static func performAction(action: CCModelAction) -> Any? {
        self.nextEditTableAction()
        switch action {
        case let .CCModelActionInitWithPrimary(initWithPrimaryProperty, value):
            return initWithPrimaryProperty(value)
        case let .CCModelActionQuery(query, condition: condition):
            return query(condition)
        case let .CCModelActionCount(count, condition: condition):
            return count(condition)
        case let .CCModelActionRemoveAll(containerId: containerId):
            if let cId = containerId {
                _removeAll(containerId: cId)
            } else {
                _removeAll()
            }
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
        self.nextEditTableAction()
        switch action {
        case let .CCModelActionReplaceIntoDB(containerId: containerId, top: top):
            if let cId = containerId {
                let updateModel = CCDBUpdateModel()
                updateModel.containerId = cId
                updateModel.model = self
                updateModel.top = top
                CCDBUpdateManager.shared.addModel(model: updateModel)
            } else {
                CCDBUpdateManager.shared.addModel(model: self)
            }
            guard let propertyMapper = CCModelMapperManager.shared.getMapperWithType(Self.self) else {
                return nil
            }
            CCModelNotifierManager.shared.sendViewUpdateNotify(type: Self.self)
        case let .CCModelActionRemove(containerId: containerId):
            if let cId = containerId {
                _removeFromDB(containerId: cId)
            } else {
                _removeFromDB()
            }
        default:
            break
        }
        return nil
    }
    
    func removeFromDB() {
        self.removeFromCache()
        performAction(action: .CCModelActionRemove(containerId: nil))
    }
    
    func removeFromDB(containerId: Int) {
        self.removeFromCache(containerId: containerId)
        performAction(action: .CCModelActionRemove(containerId: containerId))
    }
    
    static func initWithPrimaryPropertyValue(_ value: AnyHashable) -> Self? {
        
        if let res = self.initWithPrimaryPropertyFromCache(value: value) as? Self {
            return res
        }
        
        guard let res = performAction(action: .CCModelActionInitWithPrimary(_initWithPrimaryPropertyValue, value: value)) as? Self else {
            return nil
        }
        res.replaceIntoCache()
        return res
    }
    
    func replaceIntoDB() {
        self.replaceIntoCache()
        self.performAction(action: .CCModelActionReplaceIntoDB(containerId: nil, top: true))
    }
    
    func replaceIntoDB(containerId: Int, top: Bool) {
        self.replaceIntoCache(containerId: containerId, top: top)
        self.performAction(action: .CCModelActionReplaceIntoDB(containerId: containerId, top: top))
    }
    
    func notiViewUpdate() {
        
    }
    
    static func queryAll(_ isAsc: Bool) -> [Self] {
        if let res = self.loadAllFromCache(isAsc: isAsc) {
            return res as! [Self]
        }
        let condition = CCDBCondition()
        condition.ccIsAsc(isAsc: isAsc)
        guard let res = performAction(action: .CCModelActionQuery(_query, condition: condition)) as? [Self] else {
            return [Self]()
        }
        for obj in res {
            obj.replaceIntoCache()
        }
        return res
    }
    
    static func queryAll(_ isAsc: Bool, withContainerId containerId: Int) -> [Self] {
        if let res = self.loadAllFromCache(containerId: containerId, isAsc: isAsc) {
            return res as! [Self]
        }
        let condition = CCDBCondition()
        condition.ccIsAsc(isAsc: isAsc).ccContainerId(containerId: containerId)
        guard let res = performAction(action: .CCModelActionQuery(_query, condition: condition)) as? [Self] else {
            return [Self]()
        }
        
        for obj in res {
            obj.replaceIntoCache(containerId: containerId, top: !isAsc)
        }
        return res
    }
    
    static func query(_ condition: CCDBCondition) -> [Self] {
        guard let res = performAction(action: .CCModelActionQuery(_query, condition: condition)) as? [Self] else {
            return [Self]()
        }
        return res
    }
    
    static func removeAll() {
        self.removeAllFromCache()
        performAction(action: .CCModelActionRemoveAll(containerId: nil))
    }
    
    static func removeAll(containerId: Int) {
        self.removeAllFromCache(containerId: containerId)
        performAction(action: .CCModelActionRemoveAll(containerId: containerId))
    }
    
    static func count() -> Int {
        guard let res = performAction(action: .CCModelActionCount(_count, condition: CCDBCondition())) as? Int else {
            return 0
        }
        return res
    }
    
    static func count(_ condition: CCDBCondition) -> Int {
        guard let res = performAction(action: .CCModelActionCount(_count, condition: condition)) as? Int else {
            return 0
        }
        return res
    }
    
    static func createIndex(propertyName: String) {
        performAction(action: .CCModelActionCreateIndex(propertyName: propertyName))
    }
    
    static func removeIndex(propertyName: String) {
        performAction(action: .CCModelActionRemoveIndex(propertyName: propertyName))
    }
    
    static func addViewNotifier(notifier: @escaping ()->Void) {
        let propertyMapper = CCModelMapperManager.shared.getMapperWithType(Self.self)
        propertyMapper?.viewNotifier.append(notifier)
    }
    
    static func addViewNotifier(notifier: CCViewModel) {
        let propertyMapper = CCModelMapperManager.shared.getMapperWithType(Self.self)
        propertyMapper?.needNotifierViews.append(notifier)
    }
    
    static func removeViewNotifier(notifier: CCViewModel) {
        if let propertyMapper = CCModelMapperManager.shared.getMapperWithType(Self.self) {
            propertyMapper.needNotifierViews = propertyMapper.needNotifierViews.filter({ view in
                return view.id != notifier.id
            })
        }
        
    }
}
