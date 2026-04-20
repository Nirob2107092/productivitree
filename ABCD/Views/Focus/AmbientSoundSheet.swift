//
//  AmbientSoundSheet.swift
//  ABCD
//

import SwiftUI

struct AmbientSoundSheet: View {
    @ObservedObject var service: AmbientSoundService
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if service.soundUnavailable {
                    unavailableBanner
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(AmbientSound.allCases) { sound in
                        soundButton(sound)
                    }
                }
                .padding(.horizontal)

                if service.currentSound != nil {
                    volumeSlider
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .padding(.top, 12)
            .navigationTitle("Ambient Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Stop") {
                        service.stop()
                    }
                    .disabled(service.currentSound == nil)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Pieces

    private var unavailableBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Audio file not found")
                    .font(.footnote)
                    .fontWeight(.semibold)
                Text("Add looping audio files (rain.mp3, cafe.mp3, white_noise.mp3, forest.mp3) to the Xcode project to enable ambient sounds.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private func soundButton(_ sound: AmbientSound) -> some View {
        let isSelected = service.currentSound == sound
        return Button {
            service.toggle(sound)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: sound.iconName)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .primary)
                Text(sound.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private var volumeSlider: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .foregroundColor(.secondary)
            Slider(
                value: Binding(
                    get: { service.volume },
                    set: { service.setVolume($0) }
                ),
                in: 0...1
            )
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(.secondary)
        }
    }
}
