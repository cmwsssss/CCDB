//
//  CCModelSavingable+decodeable.swift
//  CCModelExample
//
//  Created by cmw on 2021/11/17.
//

import Foundation
import Combine

public extension CCModelSavingable {
    
    private static func headPointerOfStruct(target: inout Any) -> UnsafeMutablePointer<Byte> {

        return withUnsafeMutablePointer(to: &target) {
            return UnsafeMutableRawPointer($0).bindMemory(to: Byte.self, capacity: 8)
        }
    }
    
    private static func headPointerOfClass(target: Any) -> UnsafeMutablePointer<Byte> {

        let opaquePointer = Unmanaged.passUnretained(target as AnyObject).toOpaque()
        let mutableTypedPointer = opaquePointer.bindMemory(to: Byte.self, capacity: 8)
        return UnsafeMutablePointer<Byte>(mutableTypedPointer)
    }
    
    private static func writePublisedValue(value: Any, finalLevel: Bool, inValueType: Any.Type, inValue: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        if finalLevel {
            for child in mirror.children {
                if child.label == "currentValue" || child.label == "value" {
                    let childType = type(of: value)
                    if let properties = getProperties(forType: childType) {
                        let headPoint : UnsafeMutablePointer<Byte>
                        headPoint = headPointerOfClass(target: value)
                        
                        for property in properties {
                            if property.key == "currentValue" {
                                let address = headPoint.advanced(by: property.offset)
                                let propertyDetail = PropertyInfo(key: property.key, type: property.type, address: address, bridged: false)
                                extensions(of: inValueType).write(inValue, to: propertyDetail.address)
                            }
                        }
                    }
                    
                    return child.value
                }
            }
        } else {
            for child in mirror.children {
                if child.label == "currentValue" || child.label == "value" {
                    return nil
                }
                else {
                    if child.label == "subject" {
                        if let finalValue = writePublisedValue(value: child.value, finalLevel: true, inValueType: inValueType, inValue: inValue) {
                            return finalValue
                        }
                    } else {
                        if let finalValue = writePublisedValue(value: child.value, finalLevel: false, inValueType: inValueType, inValue: inValue) {
                            return finalValue
                        }
                    }
                }
            }
        }
        return nil
    }
    
    private static func setupFromSelfModel(model: Any, primaryValue: AnyHashable, properties: [Property.Description]) -> Self? {
        if var instanceIn = Self.initWithPrimaryPropertyValue(primaryValue) {
            guard let propertyMapper = CCModelMapperManager.shared.getMapperWithTypeName(Self.fastModelIndex(), type: Self.self) else {
                return nil
            }
            let rawPointerIn = instanceIn.headPointer()
            
            var instanceOut = model as? CCModelSavingable
            guard let rawPointerOut = instanceOut?.headPointer() else {
                return nil
            }
                        
            for property in properties {

                let propAddrIn = rawPointerIn.advanced(by: property.offset)
                let propAddrOut = rawPointerOut.advanced(by: property.offset)
                
                var propertyType = property.type
                if let realType = propertyMapper.publishedTypeMapper[property.key] {
                    propertyType = realType
                }
                let propertyDetailIn = PropertyInfo(key: property.key, type: propertyType, address: propAddrIn, bridged: false)
                let propertyDetailOut = PropertyInfo(key: property.key, type: propertyType, address: propAddrOut, bridged: false)
                
                guard let columnType = propertyMapper.columnType[property.key] else {
                    return nil
                }
                
                guard let value = extensions(of: property.type).value(from: propertyDetailOut.address) else {
                    return nil
                }
                
                let desc = String(describing: property.type)
                var finalValue = value
                if desc.contains("Published") {
                    if let currentValue = findPublisherCurrentValue(value: value, finalLevel: false) {
                        finalValue = currentValue
                    }
                }
                guard let inValue = extensions(of: property.type).value(from: propertyDetailIn.address) else {
                    return nil
                }
                switch columnType {
                case.CCDBColumnTypeDouble:
                    if writePublisedValue(value: inValue, finalLevel: false, inValueType: Double.self, inValue: finalValue) != nil {
                        continue
                    } else {
                        extensions(of: Double.self).write(finalValue, to: propertyDetailIn.address)
                    }
                case .CCDBColumnTypeInt:
                    if writePublisedValue(value: inValue, finalLevel: false, inValueType: Int.self, inValue: finalValue) != nil {
                        continue
                    } else {
                        extensions(of: Int.self).write(finalValue, to: propertyDetailIn.address)
                    }
                case .CCDBColumnTypeLong:
                    if writePublisedValue(value: inValue, finalLevel: false, inValueType: Int64.self, inValue: finalValue) != nil {
                        continue
                    } else {
                        extensions(of: Int64.self).write(finalValue, to: propertyDetailIn.address)
                    }
                case .CCDBColumnTypeBool:
                    if writePublisedValue(value: inValue, finalLevel: false, inValueType: Bool.self, inValue: finalValue) != nil {
                        continue
                    } else {
                        extensions(of: Bool.self).write(finalValue, to: propertyDetailIn.address)
                    }
                case .CCDBColumnTypeString:
                    if writePublisedValue(value: inValue, finalLevel: false, inValueType: String.self, inValue: finalValue) != nil {
                        continue
                    } else {
                        extensions(of: String.self).write(finalValue, to: propertyDetailIn.address)
                    }
                case .CCDBColumnTypeCustom:
                    var type = property.type
                    if let realType = propertyMapper.publishedTypeMapper[property.key] {
                        type = realType
                    }
                    if let customType = type as? CCModelSavingable.Type {
                        var mirror:Mirror = Mirror(reflecting: finalValue)
                        if mirror.children[mirror.children.startIndex].label == "some" {
                            mirror = Mirror(reflecting: mirror.children[mirror.children.startIndex].value)
                        }

                        if let primaryValue = mirror.children[mirror.children.startIndex].value as? AnyHashable,
                           let customPropertyMapper = CCModelMapperManager.shared.getMapperWithTypeName(customType.fastModelIndex(), type: type) {
                            
                            let finalObject = customType.setupFromSelfModel(model: finalValue, primaryValue: primaryValue, properties:customPropertyMapper.properties)
                            
                            if writePublisedValue(value: inValue, finalLevel: false, inValueType: type, inValue: finalObject as Any) != nil {
                                continue
                            } else {
                                extensions(of: type).write(finalObject as Any, to: propertyDetailIn.address)
                            }
                        }
                    }
                }
            }
            return instanceIn
        } else {
            return nil
        }
                
    }
    
    
    private static func createModelFromData(data: Any,properties: [Property.Description]) -> Any {
        
        let mirror:Mirror = Mirror(reflecting: data)
        if let primaryValue = mirror.children[mirror.children.startIndex].value as? AnyHashable {
            if let resModel = Self.setupFromSelfModel(model: data, primaryValue: primaryValue, properties: properties) {
                return resModel
            } else {
                return data
            }
        } else {
            return data
        }
    }
    
    static func updateWithJSON<T:Decodable>(mapper: T.Type, jsonData: Any) -> T {
        var res = [Any]()
        do {
            guard let propertyMapper = CCModelMapperManager.shared.getMapperWithTypeName(Self.fastModelIndex(), type: Self.self) else {
                return res as! T
            }
            let rawData = try JSONSerialization.data(withJSONObject: jsonData, options: .fragmentsAllowed)
            let decoder = JSONDecoder()
            let rawModelData = try decoder.decode(mapper, from: rawData)
            if let datas = rawModelData as? [Any] {
                for data in datas {
                    res.append(createModelFromData(data: data, properties: propertyMapper.properties))
                }
                for needReplaceModel in res {
                    if let model = needReplaceModel as? CCModelSavingable {
                        model.replaceIntoDB()
                    }
                }
            } else {
                let data = rawModelData as Any
                res.append(createModelFromData(data: data, properties: propertyMapper.properties))
            }
            
            return res as! T
        } catch  {
            return res as! T
        }
    }
}
