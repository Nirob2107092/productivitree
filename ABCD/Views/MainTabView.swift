//
//  MainTabView.swift
//  ABCD
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        TabView {
            // Tasks Tab
            TaskListView()
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle.fill")
                }

            // Habits Tab
            HabitListView()
                .tabItem {
                    Label("Habits", systemImage: "flame.fill")
                }

            // Focus Tab
            NavigationStack {
                Text("Focus")
                    .font(.title)
                    .navigationTitle("Focus")
            }
            .tabItem {
                Label("Focus", systemImage: "timer")
            }

            // Sessions Tab
            NavigationStack {
                Text("Sessions")
                    .font(.title)
                    .navigationTitle("Study Sessions")
            }
            .tabItem {
                Label("Sessions", systemImage: "person.2.fill")
            }

            // Profile Tab
            NavigationStack {
                VStack(spacing: 20) {
                    if let user = authService.userModel {
                        Text("Welcome, \(user.displayName)!")
                            .font(.title2)
                        Text("Level \(user.level) | \(user.xp) XP")
                            .foregroundColor(.secondary)
                    }

                    Button(role: .destructive) {
                        authService.logout()
                    } label: {
                        Text("Log Out")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
        }
        .tint(.green)
    }
}
