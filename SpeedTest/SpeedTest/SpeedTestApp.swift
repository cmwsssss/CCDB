//
//  SpeedTestApp.swift
//  SpeedTest
//
//  Created by cmw on 2021/12/13.
//

import SwiftUI
import CCDB

@main
struct SpeedTestApp: App {
    
    init() {
        CCDBConnection.initializeDBWithVersion("1.0")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
