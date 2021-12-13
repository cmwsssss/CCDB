# CCDB是什么
CCDB是基于Sqlite3和Swift编写的高性能数据库框架，非常适合用于SwiftUI的的开发
CCDB拥有一个OBJC版本，OBJC版本速度更快，支持字典->模型映射，使用时需要的代码更少，使用OC的开发者[点此查看](https://github.com/cmwsssss/CCDB-OBJC)

## 基本特性介绍

#### 易用性:
CCDB的使用非常简单，只需要一句代码就可以进行增删改查，编程者不需要关注任何数据库底层层面的操作，比如事务，数据库连接池，线程安全等等，CCDB会对应用层的API操作进行优化，保证数据库层面的高效运行

#### 高效性:
CCDB是基于sqlite3的多线程模型进行工作的，并且其拥有独立的内存缓存机制，使其性能在绝大多数时候表现比原生sqlite3更好

* 和Realm的性能对比(基于完全相同的数据模型):
<img width="872" alt="截屏2021-12-13 上午11 34 04" src="https://user-images.githubusercontent.com/16182417/145748384-0e26111c-4caf-4c21-b079-1d22401437e3.png">
    
**在写入速度上，CCDB是超过Realm的，但是在查询上，CCDB弱于Realm**
    
* CCDB提供了内存缓存，当数据需要二次获多次查询时，速度将会大幅提升
<img width="960" alt="截屏2021-12-13 下午2 59 53" src="https://user-images.githubusercontent.com/16182417/145766614-92919304-681a-4a17-acc9-a6baf7616bbc.png">

#### 适配SwiftUI:
CCDB对SwiftUI的适配进行了单独的优化，模型属性适配了@Published机制，意味着任何数据属性值的改变，都会让UI进行刷新

#### Container:
CCDB还提供了一个列表解决方案Container，可以非常简单的对列表数据进行保存和读取。

#### 单一拷贝性:
CCDB生成的对象，在内存里面只会有一份拷贝，这也是适配SwiftUI的基础

## 使用教程

#### 环境要求
CCDB支持 iOS 13 以上

#### 安装
pod 'CCDB'

#### 初始化数据库
在使用CCDB相关API之前要先调用初始化方法
```
CCDBConnection.initializeDBWithVersion("1.0")
```
如果数据模型属性有变化，需要升级数据库时，更改verson即可

#### 模型接入

##### 继承CCModelSavingable协议
**注意：CCDB的模型必须要有一个主键，该主键为模型属性中的第一个属性**
```
class UserModel: CCModelSavingable {
    var userId = "" //主键
    ...
}
```
##### 在该模型文件内实现modelConfiguration方法
```
static func modelConfiguration() -> CCModelConfiguration {
    var configuration = CCModelConfiguration(modelInit: UserModel.init)
    ...
    return configuration
}
```
做完上面两步以后，就可以开始使用该模型进行数据库操作了。
CCDB支持的类型有：Int，String，Double，Float，Bool以及继承自CCModelSavingable的类。

##### 自定义类型：
如果模型属性中有一些CCDB不支持的类型，比如数组，字典，或者非CCModelSavingable的对象，则需要一些额外的代码来对这些数据进行编解码后保存和读取
```
class UserModel: CCModelSavingable {
    var userId = "" //主键
    var photoIds = [String]()  //自定义数组
    var height: OptionModel?  //自定义的类型
}
```

```
//在该处对特殊属性进行配置
static func modelConfiguration() -> CCModelConfiguration {
    var configuration = CCModelConfiguration(modelInit: UserModel.init)
    //对photoIds的值进行手动处理
    configuration.inOutPropertiesMapper["photoIds"] = true  
    
    //对height的值进行手动处理
    configuration.inOutPropertiesMapper["height"] = true  
    
    //指定自定义属性的编码方法
    configuration.intoDBMapper = intoDBMapper 
    
    //指定自定义属性的解码方法
    configuration.outDBMapper = outDBMapper 
    ...
    return configuration
}
```

* 自定义数据编码：将自定义数据编码为JSON字符串
```
static func intoDBMapper(instance: Any)->String {
        
    guard let model = instance as? UserModel else {
        return ""
    }
        
    var dicJson = [String: Any]()
    dicJson["photoIds"] = photoIds
        
    if let height = model.height {
        dicJson["height"] = height.optionId
    }
        
    do {
        let json = try JSONSerialization.data(withJSONObject: dicJson, options: .fragmentsAllowed)
        return String(data: json, encoding: .utf8) ?? ""
    } catch  {
        return ""
    }
}
```
* 自定义数据解码：对数据库内的JSON字符串进行解码并填充到属性

```
static func outDBMapper(instance: Any, rawData: String) {
    do {
        guard let model = instance as? UserModel else {
            return
        }
        if let data = rawData.data(using: .utf8) {
            if let jsonDic = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? Dictionary<String, Any> {
                if let photoIds = jsonDic["photoIds"] as? [String] {
                    model.photoIds = photoIds
                        }
                    }
                }
                    
                if let heightId = jsonDic["height"] as? String {
                    model.height = OptionModel(optionId: heightId)
                }
            }
        }
    } catch  {
            
    }
}
```
#### 支持@Published：
如果你希望模型属性值绑定到SwiftUI的页面元素，则需要使用@Published来包装属性，这些被包装的属性同样需要在modelConfiguration内进行配置
```
class UserModel: CCModelSavingable {
    var userId = "" //主键
    @Published var username = ""
    @Published var age = 0
    ...
}
```
* 需要将该属性的type传入Mapper内，key的值为 **_属性名**
```
static func modelConfiguration() -> CCModelConfiguration {
    var configuration = CCModelConfiguration(modelInit: UserModel.init)
    //_username为key，value是username这个属性的type
    configuration.publishedTypeMapper["_username"] = String.self   
    configuration.publishedTypeMapper["_age"] = Int.self
    ...
    return configuration
}
```

#### 更新和插入
对于CCDB来说，操作都是基于CCModelSavingable对象的，**对象必须具有主键**，因此更新和插入都是下面这句代码，如果数据内没有该主键对应数据，则会插入，否则则会更新。
**CCDB不提供批量写入接口，CCDB会自动建立写入事务并优化**
```
userModel.replaceIntoDB()
```

#### 查询
CCDB提供了针对单独对象的主键查询，批量查询和条件查询的接口

##### 主键查询
通过主键获取对应的模型对象
```
let user = UserModel.initWithPrimaryPropertyValue("userId")
```
##### 批量查询
* 获取该模型表的长度
```
let count = UserModel.count()
```
* 获取该模型表下所有对象
```
let users = UserModel.queryAll(isAsc: false)    //倒序 
```

##### 条件查询
CCDB的条件配置是通过CCDBCondition的对象来完成的
比如查询UserModel表内前30个Age大于20的用户，结果按照倒Age的倒序返回
```
let condition = CCDBCondition()
//cc相关方法没有顺序先后之分
condition.ccWhere(whereSql: "Age > 30").ccOrderBy(orderBy: "Age").ccLimit(limit: 30).ccOffset(offset: 0).ccIsAsc(isAsc: false)

//根据条件查询对应用户
let res = UserModel.query(condition)

//根据条件获取对应的用户数量
let count = UserModel.count(condition)
```

#### 删除
* 删除单个对象
```
userModel.removeFromDB()
```
* 删除所有对象
```
UserModel.removeAll()
```

#### 索引
* 建立索引
```
//给Age属性建立索引
UserModel.createIndex("Age")
```
* 删除索引
```
//删除Age属性索引
UserModel.removeIndex("Age")
```

#### Container
Container是一种列表数据的解决方案，可以将各个列表的值写入到Container内，Container表内数据不是单独的拷贝，其与数据表的数据相关联

```
let glc = Car()
glc.name = "GLC 300"
glc.brand = "Benz"
// 假设Benz车的containerId为1，这里会将glc写入Benz车的列表容器内
glc.replaceIntoDB(containerId: 1, top: false)

//获取所有Benz车的列表数据
let allBenzCar = Car.queryAll(false, withContainerId: 1)

//将glc从Benz车列表中移除
glc.removeFromDB(containerId: 1)
```
Container的数据存取在CCDB内部同样有过专门优化，可以不用考虑性能问题

#### SwiftUI适配
CCDB支持@Published包装器，只需要添加几句代码，当被包装的属性发生变更时，就可以通知界面进行更新

```
class UserModel: CCModelSavingable, ObservableObject, Identifiable {
    var userId = ""
    @Published var username = ""
    ...
    
    //按照该方式，实现该协议方法
    func notiViewUpdate() {
        self.objectWillChange.send()
    }
}

class SomeViewModel: ObservableObject {
    @Published var users = [UserModel]()
    init() {
        weak var weakSelf = self
        //添加该代码，UserModel属性发生变更时，通知界面变更
        UserModel.addViewNotifier {
            weakSelf?.objectWillChange.send()
        }
    }
}

class SomeView: View {
    @ObservedObject var viewModel: SomeViewModel
    var body: some View {
        List(self.viewModel.users) {user in
            Text(user.username)
        }
    }
}
```
