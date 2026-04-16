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
    @StateObject private var authService = AuthService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}
