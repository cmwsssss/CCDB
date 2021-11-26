//
//  CCModelSavingable+typeDecode.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/16.
//

import Foundation

extension CCModelSavingable {
    static func decodeInt32Type(value: Int32, targetType:Any.Type) -> Any? {
        if (targetType == Int.self) {
            return Int(value)
        } else if (targetType == Int32.self) {
            return value
        } else if (targetType == Int8.self) {
            return Int8(value)
        } else if (targetType == Int16.self) {
            return Int16(value)
        } else if (targetType == Int64.self) {
            return Int64(value)
        }
        return nil
    }
    
    static func decodeInt64Type(value: Int64, targetType:Any.Type) -> Any? {
        if (targetType == Int.self) {
            return Int(value)
        } else if (targetType == Int32.self) {
            return Int32(value)
        } else if (targetType == Int8.self) {
            return Int8(value)
        } else if (targetType == Int16.self) {
            return Int16(value)
        } else if (targetType == Int64.self) {
            return value
        }
        return nil
    }
    
    static func decodeDoubleType(value: Double, targetType:Any.Type) -> Any? {
        if (targetType == Double.self) {
            return value
        } else if (targetType == Float.self) {
            return Float(value)
        } else if (targetType == Float16.self) {
            return Float16(value)
        } else if (targetType == Float32.self) {
            return Float32(value)
        } else if (targetType == Float64.self) {
            return Float64(value)
        } else if (targetType == Float80.self) {
            return Float80(value)
        }
        return nil
    }
}
