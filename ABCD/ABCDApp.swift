//
//  ABCDApp.swift
//  ABCD
//
//  Created by Nahian Zarif on 11/4/26.
//

import SwiftUI
import FirebaseCore

@main
struct ABCDApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
