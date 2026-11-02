//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    /// Player settings bar anchored to the bottom trailing corner, beside the progress bar.
    struct BottomActionBar: View {

        @AdaptiveLayout
        private var viewLayout

        var body: some View {
            Toolbar.ActionButtons()
                .frame(height: viewLayout.toolbarButtonSize)
                .font(.system(size: 22, weight: .semibold))
                .menuStyle(OverlayMenuStyle())
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
