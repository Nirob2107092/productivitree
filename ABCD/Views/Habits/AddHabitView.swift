//
//  AddHabitView.swift
//  ABCD
//

import SwiftUI
import FirebaseAuth

struct AddHabitView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject var viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit Details") {
                    TextField("e.g. Read 30 minutes", text: $title)
                }

                Section {
                    Text("You'll earn +\(Constants.XP.habitCompleted) XP each day you complete this habit.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHabit()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveHabit() {
        guard let userId = authService.currentUser?.uid else { return }
        viewModel.addHabit(
            title: title.trimmingCharacters(in: .whitespaces),
            userId: userId
        )
        dismiss()
    }
}
