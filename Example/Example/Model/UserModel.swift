//
//  UserModel.swift
//  CCModelExample
//
//  Created by cmw on 2021/11/12.
//

import Foundation

class UserModel: CCModelSavingable, ObservableObject, Identifiable, Decodable {
    var userId = ""
    @Published var username = ""
    @Published var info = ""
    @Published var avatar: PhotoModel?
    @Published var photos = [PhotoModel]()
    @Published var height: OptionModel?
    @Published var viewCount: Int?
    @Published var liked: Bool?
    
    enum CodingKeys: String, CodingKey {
        case userId = "userId"
        case username = "username"
        case info = "Info"
        case avatar = "avatar"
        case photos = "photos"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = container.decodeString(forKey: .userId)
        self.username = container.decodeString(forKey: .username)
        self.info = container.decodeString(forKey: .info)
        self.avatar = try? container.decodeIfPresent(PhotoModel.self, forKey: .avatar)
        if let arr = try? container.decodeIfPresent([PhotoModel].self, forKey: .photos) {
            self.photos = arr
        }
    }
    
    func notiViewUpdate() {
        self.objectWillChange.send()
    }
    
    init() {
        
    }
    
    static func modelConfiguration() -> CCModelConfiguration {
        var configuration = CCModelConfiguration(modelInit: UserModel.init)
        configuration.publishedTypeMapper["_username"] = String.self
        configuration.publishedTypeMapper["_info"] = String.self
        configuration.publishedTypeMapper["_avatar"] = PhotoModel.self
        configuration.publishedTypeMapper["_viewCount"] = Int?.self
        configuration.publishedTypeMapper["_liked"] = Bool?.self
        configuration.inOutPropertiesMapper["_photos"] = true
        configuration.inOutPropertiesMapper["_height"] = true
        configuration.intoDBMapper = intoDBMapper
        configuration.outDBMapper = outDBMapper
        return configuration
    }
    
}

extension UserModel {
    static func intoDBMapper(instance: Any)->String {
        
        guard let model = instance as? UserModel else {
            return ""
        }
        
        var dicJson = [String: Any]()
        
        var photoIds = [String]()
        
        for photo in model.photos {
            photo.replaceIntoDB()
            photoIds.append(photo.photoId)
        }
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
    
    static func outDBMapper(instance: Any, rawData: String) {
        do {
            guard let model = instance as? UserModel else {
                return
            }
            if let data = rawData.data(using: .utf8) {
                if let jsonDic = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? Dictionary<String, Any> {
                    if let photoIds = jsonDic["photoIds"] as? [String] {
                        for photoId in photoIds {
                            if let photo = PhotoModel.initWithPrimaryPropertyValue(photoId) {
                                model.photos.append(photo)
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
}
