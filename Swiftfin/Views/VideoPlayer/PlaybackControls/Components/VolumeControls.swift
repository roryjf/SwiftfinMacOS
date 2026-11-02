//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    /// Centered indicator shown briefly when the volume changes.
    struct VolumeIndicator: View {

        @Environment(VolumeController.self)
        private var volume: VolumeController?

        private let barWidth: CGFloat = 120

        var body: some View {
            ZStack {
                if let volume, volume.isShowingIndicator {
                    VStack(spacing: 14) {
                        Image(systemName: volume.systemImage)
                            .font(.system(size: 52, weight: .semibold))
                            .contentTransition(.symbolEffect(.replace))
                            .frame(height: 56)

                        Capsule()
                            .fill(.white.opacity(0.25))
                            .frame(width: barWidth, height: 6)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(.white)
                                    .frame(width: barWidth * volume.effectiveLevel)
                            }

                        Text(volume.isMuted ? "Muted" : "\(Int((volume.volume * 100).rounded()))%")
                            .font(.callout.weight(.medium))
                            .monospacedDigit()
                    }
                    .foregroundStyle(.white)
                    .padding(28)
                    .frame(minWidth: 190)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .animation(.easeOut(duration: 0.15), value: volume?.isShowingIndicator ?? false)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
        }
    }

    /// Speaker button that mutes on click. Hovering it opens the volume slider.
    struct VolumeButton: View {

        @Environment(VolumeController.self)
        private var volume: VolumeController?

        var body: some View {
            if let volume {
                VolumeButtonContent(volume: volume)
            }
        }
    }

    private struct VolumeButtonContent: View {

        let volume: VolumeController

        var body: some View {
            Button {
                volume.toggleMute()
            } label: {
                Label("Volume", systemImage: volume.systemImage)
                    .labelStyle(.iconOnly)
            }
            .help("Mute")
            .onHover { volume.setHoveringButton($0) }
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                volume.buttonFrame = frame
            }
            .onDisappear { volume.closeSlider() }
        }
    }

    /// Draws the vertical slider on the top layer of the controls, above the progress bar.
    struct VolumeSliderOverlay: View {

        static let panelHeight: CGFloat = 110 + 2 * 14

        @Environment(VideoPlayer.ViewState.self)
        private var viewState
        @Environment(VolumeController.self)
        private var volume: VolumeController?

        var body: some View {
            if let volume {
                GeometryReader { proxy in
                    let origin = proxy.frame(in: .global).origin

                    if volume.isSliderOpen, viewState.isPresentingControls, volume.buttonFrame != .zero {
                        VolumeSliderPanel(volume: volume)
                            .position(
                                x: volume.buttonFrame.midX - origin.x,
                                y: volume.buttonFrame.minY - origin.y - Self.panelHeight / 2
                            )
                            .transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: 0.12), value: volume.isSliderOpen)
                .onChange(of: viewState.isPresentingControls) {
                    if !viewState.isPresentingControls {
                        volume.closeSlider()
                    }
                }
            }
        }
    }

    private struct VolumeSliderPanel: View {

        private static let sliderHeight: CGFloat = 110
        private static let knobSize: CGFloat = 14
        private static let padding: CGFloat = 14

        @Environment(VideoPlayer.ViewState.self)
        private var viewState

        @State
        private var interactionID = UUID()

        let volume: VolumeController

        private var travel: CGFloat {
            Self.sliderHeight - Self.knobSize
        }

        var body: some View {
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 6)

                Capsule()
                    .fill(.white)
                    .frame(width: 6, height: Self.knobSize / 2 + travel * volume.effectiveLevel)

                Circle()
                    .fill(.white)
                    .frame(width: Self.knobSize, height: Self.knobSize)
                    .offset(y: -travel * volume.effectiveLevel)
            }
            .frame(width: 36, height: Self.sliderHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        volume.setDraggingSlider(true)
                        viewState.setInteraction(.menu(interactionID), active: true)

                        let level = 1 - (value.location.y - Self.knobSize / 2) / travel
                        volume.setVolume(level, showIndicator: false)
                    }
                    .onEnded { _ in
                        volume.setDraggingSlider(false)
                        viewState.setInteraction(.menu(interactionID), active: false)
                    }
            )
            .padding(.vertical, Self.padding)
            .padding(.horizontal, 6)
            .background(.black.opacity(0.65), in: Capsule())
            .onHover { volume.setHoveringPanel($0) }
            .onDisappear {
                viewState.setInteraction(.menu(interactionID), active: false)
            }
        }
    }
}
