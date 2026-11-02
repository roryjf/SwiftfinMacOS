//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Observation
import SwiftUI

/// Player volume that survives between episodes, with a transient on-screen indicator.
@MainActor
@Observable
final class VolumeController {

    private static let volumeKey = "swiftfin.player.volume"
    private static let mutedKey = "swiftfin.player.muted"

    private(set) var volume: Double
    private(set) var isMuted: Bool
    private(set) var isShowingIndicator = false

    /// True while the volume slider is open, so other hover targets underneath it step aside.
    private(set) var isSliderOpen = false

    /// Where the volume button is on screen, so the slider can be drawn above everything else.
    var buttonFrame: CGRect = .zero

    @ObservationIgnored
    private var isHoveringButton = false
    @ObservationIgnored
    private var isHoveringPanel = false
    @ObservationIgnored
    private var isDraggingSlider = false
    @ObservationIgnored
    private var sliderHideTask: Task<Void, Never>?

    @ObservationIgnored
    private weak var mediaSession: MediaSession?
    @ObservationIgnored
    private var hideTask: Task<Void, Never>?

    init() {
        let defaults = UserDefaults.standard

        volume = defaults.object(forKey: Self.volumeKey) as? Double ?? 1
        isMuted = defaults.bool(forKey: Self.mutedKey)
    }

    /// The level the user hears, after muting.
    var effectiveLevel: Double {
        isMuted ? 0 : volume
    }

    var systemImage: String {
        switch effectiveLevel {
        case 0: "speaker.slash.fill"
        case ..<0.34: "speaker.wave.1.fill"
        case ..<0.67: "speaker.wave.2.fill"
        default: "speaker.wave.3.fill"
        }
    }

    private var provider: (any MediaPlayerVolumeProviding)? {
        mediaSession?.player as? any MediaPlayerVolumeProviding
    }

    /// Applies the remembered volume to the session's current player.
    func apply(to mediaSession: MediaSession) {
        self.mediaSession = mediaSession
        push()
    }

    func setVolume(_ newValue: Double, unmuting: Bool = true, showIndicator: Bool = true) {
        volume = clamp(newValue, min: 0, max: 1)

        if unmuting, volume > 0 {
            isMuted = false
        }

        commit(showIndicator: showIndicator)
    }

    func adjust(by delta: Double) {
        setVolume(volume + delta, unmuting: delta > 0)
    }

    func toggleMute() {
        isMuted.toggle()
        commit(showIndicator: true)
    }

    func setHoveringButton(_ isHovering: Bool) {
        isHoveringButton = isHovering
        updateSlider()
    }

    func setHoveringPanel(_ isHovering: Bool) {
        isHoveringPanel = isHovering
        updateSlider()
    }

    func setDraggingSlider(_ isDragging: Bool) {
        isDraggingSlider = isDragging
        updateSlider()
    }

    func closeSlider() {
        sliderHideTask?.cancel()
        isHoveringButton = false
        isHoveringPanel = false
        isDraggingSlider = false
        isSliderOpen = false
    }

    private func updateSlider() {
        sliderHideTask?.cancel()

        if isHoveringButton || isHoveringPanel || isDraggingSlider {
            isSliderOpen = true
        } else {
            sliderHideTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }

                self?.isSliderOpen = false
            }
        }
    }

    private func commit(showIndicator: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(volume, forKey: Self.volumeKey)
        defaults.set(isMuted, forKey: Self.mutedKey)

        push()

        if showIndicator {
            presentIndicator()
        }
    }

    private func push() {
        provider?.setVolume(volume)
        provider?.setMuted(isMuted)
    }

    private func presentIndicator() {
        isShowingIndicator = true

        hideTask?.cancel()
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.3))
            guard !Task.isCancelled else { return }

            self?.isShowingIndicator = false
        }
    }
}
