//
//  AmbientSound.swift
//  ABCD
//

import Foundation

enum AmbientSound: String, CaseIterable, Identifiable {
    case rain
    case cafe
    case whiteNoise
    case forest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rain: return "Rain"
        case .cafe: return "Cafe"
        case .whiteNoise: return "White Noise"
        case .forest: return "Forest"
        }
    }

    var iconName: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .whiteNoise: return "waveform"
        case .forest: return "leaf.fill"
        }
    }

    /// Bundle filename without extension. Accepts mp3/m4a/caf/wav.
    var fileName: String {
        switch self {
        case .rain: return "rain"
        case .cafe: return "cafe"
        case .whiteNoise: return "white_noise"
        case .forest: return "forest"
        }
    }
}
