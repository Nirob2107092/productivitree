//
//  ContentView.swift
//  ABCD
//
//  Created by Nahian Zarif on 11/4/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var authViewModel: AuthViewModel

    init() {
        let service = AuthService()
        _authService = StateObject(wrappedValue: service)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authService: service))
    }

    var body: some View {
        Group {
            if authService.currentUser != nil {
                MainTabView(authService: authService)
            } else {
                LoginView(viewModel: authViewModel)
            }
        }
    }
}
