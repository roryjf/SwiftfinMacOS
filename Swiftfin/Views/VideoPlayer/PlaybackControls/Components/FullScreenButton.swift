//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

#if targetEnvironment(macCatalyst)

extension VideoPlayer.PlaybackControls {

    /// Toggles the window's full screen state.
    struct FullScreenButton: View {

        @State
        private var isFullScreen = false

        private var title: String {
            isFullScreen ? "Exit Full Screen" : "Enter Full Screen"
        }

        var body: some View {
            Button {
                MacWindow.toggleFullScreen()
            } label: {
                Label(
                    title,
                    systemImage: isFullScreen
                        ? "arrow.down.right.and.arrow.up.left"
                        : "arrow.up.left.and.arrow.down.right"
                )
                .labelStyle(.iconOnly)
            }
            .help(title)
            .font(.system(size: 30, weight: .semibold))
            .buttonStyle(OverlayButtonStyle(isInBar: true))
            .frame(width: 60, height: 60)
            .if(UIDevice.supportsLiquidGlass) { view in
                view
                    .backport
                    .glassEffect(.regular.interactive(true), in: .circle)
            }
            .onAppear { isFullScreen = MacWindow.isFullScreen }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NSWindowDidEnterFullScreenNotification"))) { _ in
                isFullScreen = true
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NSWindowDidExitFullScreenNotification"))) { _ in
                isFullScreen = false
            }
        }
    }
}

#endif
