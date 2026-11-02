//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    /// One-tap subtitles on/off, independent of the subtitle options menu.
    struct SubtitleToggle: View {

        @Environment(MediaSession.self)
        private var mediaSession

        var body: some View {
            if let playbackItem = mediaSession.playbackItem,
               playbackItem.subtitleStreams.contains(where: { ($0.index ?? -1) >= 0 })
            {
                let isEnabled = playbackItem.subtitlesEnabled

                Button {
                    playbackItem.setSubtitlesEnabled(!isEnabled)
                } label: {
                    Label(
                        L10n.subtitles,
                        systemImage: isEnabled
                            ? VideoPlayerActionButton.subtitles.systemImage
                            : VideoPlayerActionButton.subtitles.secondarySystemImage
                    )
                }
                .disabled(!mediaSession.canControlPlayback)
                .help(L10n.subtitles)
            }
        }
    }
}
