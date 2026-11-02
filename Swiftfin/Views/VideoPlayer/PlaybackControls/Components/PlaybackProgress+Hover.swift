//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

#if targetEnvironment(macCatalyst)

extension VideoPlayer.PlaybackControls {

    /// Pointer hover on the progress bar: the hovered chapter grows, and a thumbnail
    /// with the timestamp and chapter title follows the cursor. Clicking seeks.
    struct HoverScrubModifier: ViewModifier {

        private struct Segment {
            let title: String?
            let start: Double
            let end: Double
        }

        private static let trackHeight: CGFloat = 10
        private static let enlargedHeight: CGFloat = 16
        private static let previewHeight: CGFloat = 90

        @Environment(MediaSession.self)
        private var mediaSession
        @Environment(VolumeController.self)
        private var volume: VolumeController?

        @State
        private var hoverX: CGFloat?
        @State
        private var popupSize: CGSize = .zero
        /// Vertical hit area added above and below the bar, so it's easy to hover.
        let inset: CGFloat
        let width: CGFloat

        private var runtimeSeconds: Double {
            (mediaSession.item.runtime ?? .zero).seconds
        }

        private var isHovering: Bool {
            hoverX != nil && width > 0 && runtimeSeconds > 0
        }

        private func fraction(at x: CGFloat) -> Double {
            guard width > 0 else { return 0 }

            return clamp(Double(x / width), min: 0, max: 1)
        }

        private var segments: [Segment] {
            guard runtimeSeconds > 0 else { return [] }

            let starts = (mediaSession.item.chapters ?? [])
                .compactMap { chapter -> (title: String, start: Double)? in
                    guard let start = chapter.startSeconds?.seconds,
                          start >= 0, start < runtimeSeconds
                    else { return nil }

                    return (chapter.displayTitle, start)
                }
                .sorted { $0.start < $1.start }

            guard starts.isNotEmpty else { return [] }

            var result: [Segment] = []

            if let first = starts.first, first.start > 0 {
                result.append(Segment(title: nil, start: 0, end: first.start / runtimeSeconds))
            }

            for (index, chapter) in starts.enumerated() {
                let end = index + 1 < starts.count ? starts[index + 1].start : runtimeSeconds

                result.append(Segment(title: chapter.title, start: chapter.start / runtimeSeconds, end: end / runtimeSeconds))
            }

            return result
        }

        private var videoAspectRatio: CGFloat {
            let ratio = (mediaSession.player as? any VideoMediaPlayer)?.videoState.videoSize.aspectRatio ?? 1.77

            return clamp(ratio, min: 0.25, max: 4)
        }

        private static func timestamp(_ seconds: Double) -> String {
            let total = max(0, Int(seconds))
            let hours = total / 3600
            let minutes = (total % 3600) / 60
            let secs = total % 60

            return hours > 0
                ? String(format: "%d:%02d:%02d", hours, minutes, secs)
                : String(format: "%d:%02d", minutes, secs)
        }

        func body(content: Content) -> some View {
            content
                .onContinuousHover { phase in
                    switch phase {
                    case let .active(location):
                        hoverX = location.x
                    case .ended:
                        hoverX = nil
                    }
                }
                .simultaneousGesture(
                    SpatialTapGesture().onEnded { value in
                        guard mediaSession.canSeek, runtimeSeconds > 0 else { return }

                        mediaSession.seek(to: .seconds(runtimeSeconds * fraction(at: value.location.x)))
                    }
                )
                .overlay(alignment: .topLeading) {
                    hoverContent
                        .allowsHitTesting(false)
                }
                .onChange(of: volume?.isSliderOpen ?? false) { _, isOpen in
                    if isOpen {
                        hoverX = nil
                    }
                }
        }

        @ViewBuilder
        private var hoverContent: some View {
            if let hoverX, isHovering {
                let hoverFraction = fraction(at: hoverX)
                let seconds = runtimeSeconds * hoverFraction
                let segment = segments.last { $0.start <= hoverFraction } ?? segments.first

                ZStack(alignment: .topLeading) {
                    enlargedChapter(segment: segment, hoverX: hoverX)

                    popup(seconds: seconds, title: segment?.title, hoverX: hoverX)
                }
                .animation(.easeOut(duration: 0.12), value: segment?.start)
            }
        }

        @ViewBuilder
        private func enlargedChapter(segment: Segment?, hoverX: CGFloat) -> some View {
            let gap: CGFloat = 1.5
            // Chapter boundaries are straight lines, so only the episode's own ends are rounded.
            let isEpisodeStart = segment.map { $0.start <= 0 } ?? true
            let isEpisodeEnd = segment.map { $0.end >= 1 } ?? true
            let start = isEpisodeStart ? 0 : width * (segment?.start ?? 0) + gap
            let end = isEpisodeEnd ? width : width * (segment?.end ?? 1) - gap
            let chapterWidth = max(0, end - start)
            let played = clamp(
                width * (mediaSession.seconds.seconds / max(runtimeSeconds, 1)) - start,
                min: 0,
                max: chapterWidth
            )

            ZStack(alignment: .leading) {
                Color.white.opacity(0.3)

                Color.white.opacity(0.35)
                    .frame(width: clamp(hoverX - start, min: 0, max: chapterWidth))

                Color.white
                    .frame(width: played)
            }
            .frame(width: chapterWidth, height: Self.enlargedHeight)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: isEpisodeStart ? Self.enlargedHeight / 2 : 0,
                    bottomLeadingRadius: isEpisodeStart ? Self.enlargedHeight / 2 : 0,
                    bottomTrailingRadius: isEpisodeEnd ? Self.enlargedHeight / 2 : 0,
                    topTrailingRadius: isEpisodeEnd ? Self.enlargedHeight / 2 : 0
                )
            )
            .offset(x: start, y: inset - (Self.enlargedHeight - Self.trackHeight) / 2)
        }

        private func popup(seconds: Double, title: String?, hoverX: CGFloat) -> some View {
            VStack(spacing: 6) {
                if let provider = mediaSession.playbackItem?.previewImageProvider {
                    HoverPreviewImage(previewImageProvider: provider, seconds: seconds)
                        .aspectRatio(videoAspectRatio, contentMode: .fit)
                        .frame(height: Self.previewHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.white.opacity(0.9), lineWidth: 2)
                        }
                }

                HStack(spacing: 8) {
                    Text(Self.timestamp(seconds))
                        .monospacedDigit()

                    if let title, title.isNotEmpty {
                        Text(title)
                            .lineLimit(1)
                    }
                }
                .font(.callout.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(.black.opacity(0.65), in: Capsule())
            }
            .fixedSize()
            .trackingSize($popupSize)
            .offset(
                x: clamp(hoverX - popupSize.width / 2, min: 0, max: max(0, width - popupSize.width)),
                y: inset - popupSize.height - 14
            )
        }
    }

    private struct HoverPreviewImage: View {

        let previewImageProvider: PreviewImageProvider
        let seconds: Double

        @State
        private var image: UIImage?

        var body: some View {
            ZStack {
                Color.black

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .task(id: Int(seconds), priority: .userInitiated) {
                let newImage = await previewImageProvider.image(for: .seconds(seconds))
                guard !Task.isCancelled else { return }

                image = newImage
            }
        }
    }
}

#endif
