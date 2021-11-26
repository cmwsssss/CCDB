/*
 * Copyright 1999-2101 Alibaba Group.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
//  AnyExtension.swift
//  HandyJSON
//
//  Created by zhouzhuo on 08/01/2017.
//

protocol AnyExtensions {}

extension AnyExtensions {

    public static func isValueTypeOrSubtype(_ value: Any) -> Bool {
        return value is Self
    }

    public static func value(from storage: UnsafeRawPointer) -> Any? {
        let value = try? storage.assumingMemoryBound(to: self).pointee
        if (value == nil) {
            return nil
        }
        if value is Int {
            return value
        } else if value is Int32 {
            return Int(value as? Int32 ?? 0)
        } else if value is Int64 {
            return Int(value as? Int64 ?? 0)
        } else if value is Int8 {
            return Int(value as? Int8 ?? 0)
        } else if value is Int16 {
            return Int(value as? Int16 ?? 0)
        } else if value is Double {
            return value
        } else if value is Float {
            return Double(value as? Float ?? 0)
        }
        return storage.assumingMemoryBound(to: self).pointee
    }

    public static func write(_ value: Any, to storage: UnsafeMutableRawPointer) {
        guard let this = value as? Self else {
            return
        }
        storage.assumingMemoryBound(to: self).pointee = this
    }

    public static func takeValue(from anyValue: Any) -> Self? {
        return anyValue as? Self
    }
}

func extensions(of type: Any.Type) -> AnyExtensions.Type {
    struct Extensions : AnyExtensions {}
    var extensions: AnyExtensions.Type = Extensions.self
    withUnsafePointer(to: &extensions) { pointer in
        UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: Any.Type.self).pointee = type
    }
    return extensions
}

func extensions(of value: Any) -> AnyExtensions {
    struct Extensions : AnyExtensions {}
    var extensions: AnyExtensions = Extensions()
    withUnsafePointer(to: &extensions) { pointer in
        UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: Any.self).pointee = value
    }
    return extensions
}

/// Tests if `value` is `type` or a subclass of `type`
func value(_ value: Any, is type: Any.Type) -> Bool {
    return extensions(of: type).isValueTypeOrSubtype(value)
}

/// Tests equality of any two existential types
func == (lhs: Any.Type, rhs: Any.Type) -> Bool {
    return Metadata(type: lhs) == Metadata(type: rhs)
}

// MARK: AnyExtension + Storage
extension AnyExtensions {

    mutating func storage() -> UnsafeRawPointer {
        if type(of: self) is AnyClass {
            let opaquePointer = Unmanaged.passUnretained(self as AnyObject).toOpaque()
            return UnsafeRawPointer(opaquePointer)
        } else {
            return withUnsafePointer(to: &self) { pointer in
                return UnsafeRawPointer(pointer)
            }
        }
    }
}


protocol UTF8Initializable {
    init?(validatingUTF8: UnsafePointer<CChar>)
}

extension String : UTF8Initializable {}

extension Array where Element : UTF8Initializable {

    init(utf8Strings: UnsafePointer<CChar>) {
        var strings = [Element]()
        var pointer = utf8Strings
        while let string = Element(validatingUTF8: pointer) {
            strings.append(string)
            while pointer.pointee != 0 {
                pointer.advance()
            }
            pointer.advance()
            guard pointer.pointee != 0 else {
                break
            }
        }
        self = strings
    }
}

extension Strideable {
    mutating func advance() {
        self = advanced(by: 1)
    }
}

extension UnsafePointer {

    init<T>(_ pointer: UnsafePointer<T>) {
        self = UnsafeRawPointer(pointer).assumingMemoryBound(to: Pointee.self)
    }
}

func relativePointer<T, U, V>(base: UnsafePointer<T>, offset: U) -> UnsafePointer<V> where U : FixedWidthInteger {
    return UnsafeRawPointer(base).advanced(by: Int(integer: offset)).assumingMemoryBound(to: V.self)
}

extension Int {
    fileprivate init<T : FixedWidthInteger>(integer: T) {
        switch integer {
        case let value as Int: self = value
        case let value as Int32: self = Int(value)
        case let value as Int16: self = Int(value)
        case let value as Int8: self = Int(value)
        default: self = 0
        }
    }
}
