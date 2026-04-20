//
//  AmbientSoundService.swift
//  ABCD
//

import Foundation
import AVFoundation

class AmbientSoundService: ObservableObject {
    @Published var currentSound: AmbientSound?
    @Published var volume: Float = 0.6
    @Published var soundUnavailable: Bool = false

    private var player: AVAudioPlayer?

    // MARK: - Toggle

    func toggle(_ sound: AmbientSound) {
        if currentSound == sound {
            stop()
        } else {
            play(sound)
        }
    }

    // MARK: - Play

    func play(_ sound: AmbientSound) {
        stop()

        let candidates = ["mp3", "m4a", "caf", "wav"]
        let url = candidates
            .lazy
            .compactMap { Bundle.main.url(forResource: sound.fileName, withExtension: $0) }
            .first

        guard let url = url else {
            print("AmbientSoundService: missing audio file '\(sound.fileName).[mp3/m4a/caf/wav]' in bundle")
            soundUnavailable = true
            currentSound = nil
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = volume
            newPlayer.prepareToPlay()
            newPlayer.play()

            self.player = newPlayer
            self.currentSound = sound
            self.soundUnavailable = false
        } catch {
            print("AmbientSoundService error: \(error)")
            soundUnavailable = true
            currentSound = nil
        }
    }

    // MARK: - Stop

    func stop() {
        player?.stop()
        player = nil
        currentSound = nil
    }

    // MARK: - Volume

    func setVolume(_ newVolume: Float) {
        volume = newVolume
        player?.volume = newVolume
    }
}
