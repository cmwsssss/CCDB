//
//  ExampleApp.swift
//  Example
//
//  Created by cmw on 2021/11/26.
//

import SwiftUI
import CCDB

@main
struct ExampleApp: App {
    init() {
        CCDBConnection.initializeDBWithVersion("1.0")
    }
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
