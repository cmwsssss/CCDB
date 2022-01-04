//
//  CCDBStatement.swift
//  CCModelSwift
//
//  Created by cmw on 2021/7/13.
//

import Foundation
import SQLite3

public enum CCDBColumnType {
    case CCDBColumnTypeInt
    case CCDBColumnTypeBool
    case CCDBColumnTypeLong
    case CCDBColumnTypeDouble
    case CCDBColumnTypeString
    case CCDBColumnTypeCustom
}

enum CCDBStatementReturnType {
    case CCDBStatementReturnTypeInt((_ index: Int32) -> (Int32))
    case CCDBStatementReturnTypeBool((_ index: Int32) -> (Bool))
    case CCDBStatementReturnTypeLong((_ index: Int32) -> (Int64))
    case CCDBStatementReturnTypeDouble((_ index: Int32) -> (Double))
    case CCDBStatementReturnTypeString((_ index: Int32) -> (String))
}

enum CCDBStatementBindType {
    case CCDBStatementBindTypeInt((_ index: Int32, _ value: Int32) -> (Void))
    case CCDBStatementBindTypeBool((_ index: Int32, _ value: Bool) -> (Void))
    case CCDBStatementBindTypeLong((_ index: Int32, _ value: Int64) -> (Void))
    case CCDBStatementBindTypeDouble((_ index: Int32, _ value: Double) -> (Void))
    case CCDBStatementBindTypeString((_ index: Int32, _ value: String) -> (Void))
}



class CCDBStatement {
    var stmt: OpaquePointer?
    
    init(withDBInstance instance: OpaquePointer?, withSql sql:String) {
        guard sqlite3_prepare_v2(instance, sql.cString(using: String.Encoding.utf8), -1, &(self.stmt), nil) == SQLITE_OK else {
            assertionFailure("sqlite3_prepare_v2 failed")
            return
        }
    }
    
    func step() -> Int32 {
        return sqlite3_step(self.stmt)
    }
    
    func reset() -> Int32 {
        sqlite3_reset(self.stmt)
    }
    
    func finish() -> Int32 {
        sqlite3_finalize(self.stmt)
    }
    
    private func getBool(index: Int32) -> Bool {
        return (sqlite3_column_int(self.stmt, index) != 0)
        
    }
    
    private func getInt32(index: Int32) -> Int32 {
        return sqlite3_column_int(self.stmt, index)
    }
    
    private func getInt64(index: Int32) -> Int64 {
        return sqlite3_column_int64(self.stmt, index)
    }
    
    private func getDouble(index: Int32) -> Double {
        return sqlite3_column_double(self.stmt, index)
    }
    
    private func getString(index: Int32) -> String {
        guard let cString = sqlite3_column_text(self.stmt, index) else {
            return ""
        }
        return String(cString: cString)
    }
    
    func bindBool(index: Int32, withValue value: Bool) {
        sqlite3_bind_int(self.stmt, index, ((value == true) ? 1 : 0))
    }
    
    func bindInt32(index: Int32, withValue value: Int32) {
        sqlite3_bind_int(self.stmt, index, value)
    }
    
    func bindInt64(index: Int32, withValue value: Int64) {
        sqlite3_bind_int64(self.stmt, index, value)
    }
    
    func bindDouble(index: Int32, withValue value: Double) {
        sqlite3_bind_double(self.stmt, index, value)
    }
    
    func bindString(index: Int32, withValue value: String) {
        sqlite3_bind_text(self.stmt, index, value.cString(using: String.Encoding.utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
    }
        
    
    func getValue(_ type: CCDBColumnType) -> CCDBStatementReturnType {
        switch type {
        case .CCDBColumnTypeBool:
            return CCDBStatementReturnType.CCDBStatementReturnTypeBool(getBool)
        case .CCDBColumnTypeInt:
            return CCDBStatementReturnType.CCDBStatementReturnTypeInt(getInt32)
        case .CCDBColumnTypeLong:
            return CCDBStatementReturnType.CCDBStatementReturnTypeLong(getInt64)
        case .CCDBColumnTypeDouble:
            return CCDBStatementReturnType.CCDBStatementReturnTypeDouble(getDouble)
        case .CCDBColumnTypeString, .CCDBColumnTypeCustom:
            return CCDBStatementReturnType.CCDBStatementReturnTypeString(getString)
        }
    }
    
    func bindValue(_ type: CCDBColumnType) -> CCDBStatementBindType {
        switch type {
            case .CCDBColumnTypeBool:
                return CCDBStatementBindType.CCDBStatementBindTypeBool(bindBool)
            case .CCDBColumnTypeInt:
                return CCDBStatementBindType.CCDBStatementBindTypeInt(bindInt32)
            case .CCDBColumnTypeLong:
                return CCDBStatementBindType.CCDBStatementBindTypeLong(bindInt64)
            case .CCDBColumnTypeDouble:
                return CCDBStatementBindType.CCDBStatementBindTypeDouble(bindDouble)
            case .CCDBColumnTypeString, .CCDBColumnTypeCustom:
                return CCDBStatementBindType.CCDBStatementBindTypeString(bindString)
        }
    }
    
}
