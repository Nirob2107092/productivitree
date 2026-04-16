//
//  ContentView.swift
//  ABCD
//
//  Created by Nahian Zarif on 11/4/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.currentUser != nil {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
