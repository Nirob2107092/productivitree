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
            FocusTimerView()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }

            // Sessions Tab
            StudySessionListView()
            .tabItem {
                Label("Sessions", systemImage: "person.2.fill")
            }

            // Profile Tab
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
        }
        .tint(Theme.Colors.accent)
    }
}
