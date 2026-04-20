//
//  CreateSessionView.swift
//  ABCD
//

import SwiftUI

struct CreateSessionView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject var viewModel: StudySessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var scheduledAt = Date().addingTimeInterval(60 * 60)
    @State private var category: SessionCategory = .study

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Details") {
                    TextField("Study session title", text: $title)

                    DatePicker("Time", selection: $scheduledAt, displayedComponents: [.hourAndMinute])

                    Picker("Category", selection: $category) {
                        ForEach(SessionCategory.allCases, id: \.self) { item in
                            Text(item.displayName).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button {
                        createSession()
                    } label: {
                        Text("Create Session")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(!canSave)
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && authService.currentUser != nil
    }

    private func createSession() {
        guard let userId = authService.currentUser?.uid else { return }
        let creatorName = authService.userModel?.displayName
            ?? authService.currentUser?.email?.components(separatedBy: "@").first
            ?? "Unknown"

        viewModel.createSession(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            scheduledAt: scheduledAt,
            category: category,
            creatorId: userId,
            creatorName: creatorName
        )
        dismiss()
    }
}