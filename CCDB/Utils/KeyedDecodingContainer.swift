//
//  KeyedDecodingContainer+EC.swift
//  Encholy
//
//  Created by cmw on 2021/10/20.
//

import Foundation
public extension KeyedDecodingContainer {

    func decodeStringIfPresentAndIsStringOrInt(forKey key: KeyedDecodingContainer<K>.Key) -> String? {
        if let value = try? self.decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? self.decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        return nil
    }

    func decodeIntIfPresentAndIsStringOrInt(forKey key: KeyedDecodingContainer<K>.Key) -> Int? {
        if let intValue = try? self.decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        if let stringValue = try? self.decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }
        return nil
    }

    func decodeDoubleIfPresentAndIsStringOrDouble(forKey key: KeyedDecodingContainer<K>.Key) -> Double? {
        if let doubleValue = try? self.decodeIfPresent(Double.self, forKey: key) {
            return doubleValue
        }
        if let stringValue = try? self.decodeIfPresent(String.self, forKey: key) {
            return Double(stringValue)
        }
        return nil
    }

    /// decode `Bool`
    /// true: Bool(true), Int(1), String("true"), String("1")
    /// false: Bool(false), Int(0), String("false"), String("0")
    func decodeBoolIfPresentAndIsBoolOrStringOrInt(forKey key: KeyedDecodingContainer<K>.Key) -> Bool? {
        if let boolValue = try? self.decodeIfPresent(Bool.self, forKey: key) {
            return boolValue
        }
        if let intValue = try? self.decodeIfPresent(Int.self, forKey: key) {
            switch intValue {
            case 0:
                return false
            case 1:
                return true
            default:
                break
            }
        }
        if let stringValue = try? self.decodeIfPresent(String.self, forKey: key) {
            switch stringValue.lowercased() {
            case "0", "false":
                return false
            case "1", "true":
                return true
            default:
                break
            }
        }
        return nil
    }

    func decodeString(forKey key: KeyedDecodingContainer<K>.Key, defaultValue: String = "") -> String {
        if let stringValue = self.decodeStringIfPresentAndIsStringOrInt(forKey: key) {
            return stringValue
        }
        return defaultValue
    }

    func decodeInt(forKey key: KeyedDecodingContainer<K>.Key, defaultValue: Int = 0) -> Int {
        if let intValue = self.decodeIntIfPresentAndIsStringOrInt(forKey: key) {
            return intValue
        }
        return defaultValue
    }

    func decodeDouble(forKey key: KeyedDecodingContainer<K>.Key, defaultValue: Double = 0) -> Double {
        if let doubleValue = self.decodeDoubleIfPresentAndIsStringOrDouble(forKey: key) {
            return doubleValue
        }
        return defaultValue
    }

    func decodeBool(forKey key: KeyedDecodingContainer<K>.Key, defaultValue: Bool = false) -> Bool {
        if let boolValue = self.decodeBoolIfPresentAndIsBoolOrStringOrInt(forKey: key) {
            return boolValue
        }
        return defaultValue
    }
}
