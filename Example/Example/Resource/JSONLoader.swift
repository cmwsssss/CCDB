//
//  JSONLoader.swift
//  CCModelExample
//
//  Created by cmw on 2021/11/19.
//

import Foundation
class JSONLoader {
    static func loadDatasFromJSON(filename: String) -> Any {
        let data: Data

        guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
        }

        do {
            data = try Data(contentsOf: file)
        } catch {
            fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
        }

        do {
            return try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        } catch {
            fatalError("Couldn't parse")
        }
    }
}
