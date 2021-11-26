//
//  PhotoModel.swift
//  CCModelExample
//
//  Created by cmw on 2021/11/12.
//

import Foundation

class PhotoModel: CCModelSavingable, Decodable {
    
    var photoId = ""
    @Published var url = ""
    
    enum CodingKeys: String, CodingKey {
        case photoId = "photoId"
        case url = "url"
    }
    
    init() {
        
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.photoId = container.decodeString(forKey: .photoId)
        self.url = container.decodeString(forKey: .url)
    }
    
    static func modelConfiguration() -> CCModelConfiguration {
        var configuration = CCModelConfiguration(modelInit: PhotoModel.init)
        configuration.publishedTypeMapper["_url"] = String.self
        return configuration
    }
}
