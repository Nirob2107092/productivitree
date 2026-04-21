//
//  RemoteImagePreviewSheet.swift
//  ABCD
//

import SwiftUI

struct RemoteImagePreviewItem: Identifiable {
    let id = UUID()
    let title: String
    let urlString: String
}

struct RemoteImagePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: RemoteImagePreviewItem

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(item.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                AsyncImage(url: URL(string: item.urlString)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 260)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    case .failure:
                        ContentUnavailableView(
                            "Image unavailable",
                            systemImage: "photo",
                            description: Text("The uploaded image could not be loaded.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 260)
                    @unknown default:
                        EmptyView()
                    }
                }

                Text("Uploaded image preview")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}