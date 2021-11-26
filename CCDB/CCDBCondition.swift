//
//  CCDBCondition.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/19.
//

import Foundation
/**
 Used to perform conditional queries on CCDB (用于对CCDB的数据进行条件查询)
 
 ```
 let condition = CCDBCondition()
 condition.ccWhere(whereSql: "Age > 30")
            .ccOrderBy(orderBy: "Age")
            .ccLimit(limit: 30)
            .ccOffset(offset: 0)
            .ccIsAsc(isAsc: false)
 ```
 */
class CCDBCondition {
    var isAsc :Bool = true
    var limit :Int?
    var offset :Int?
    var whereSql :String?
    var orderBy :String?
    var containerId :Int = 0
    var innerSql :String {
        guard let whereSql = self.whereSql else {
            return ""
        }
        return " WHERE " + whereSql
    }
    var copyInstance :CCDBCondition {
        let instance = CCDBCondition()
        instance.isAsc = self.isAsc
        instance.limit = self.limit
        instance.offset = self.offset
        instance.whereSql = self.whereSql
        instance.orderBy = self.orderBy
        instance.containerId = self.containerId
        return instance
    }
    
    var sql: String {
        var sql = innerSql
        if let orderBy = self.orderBy {
            if self.isAsc {
                sql = sql + " ORDER BY \(orderBy) ASC"
            } else {
                sql = sql + " ORDER BY \(orderBy) DESC"
            }
        }
        
        if let limit = self.limit {
            sql = sql + " LIMIT \(limit)"
        }
        
        if let offset = self.offset {
            sql = sql + " OFFSET \(offset)"
        }
        return sql
    }
    
    func ccIsAsc(isAsc: Bool)->Self {
        self.isAsc = isAsc
        return self
    }
    
    func ccLimit(limit: Int)->Self {
        self.limit = limit
        return self
    }
    
    func ccOffset(offset: Int)->Self {
        self.offset = offset
        return self
    }
    
    func ccWhere(whereSql: String)->Self {
        self.whereSql = whereSql
        return self
    }
    
    func ccOrderBy(orderBy: String)->Self {
        self.orderBy = orderBy
        return self
    }
    
    func ccContainerId(containerId: Int)->Self {
        self.containerId = containerId
        return self
    }
    
}
