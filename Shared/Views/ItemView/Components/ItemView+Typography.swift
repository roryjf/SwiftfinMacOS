//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    /// Sizes for the item detail header. The Mac interface maps text styles to small macOS sizes,
    /// so the header uses explicit sizes there.
    enum Typography {

        static var title: Font {
            #if targetEnvironment(macCatalyst)
            .system(size: 44, weight: .semibold)
            #else
            .largeTitle
            #endif
        }

        static var description: Font {
            #if targetEnvironment(macCatalyst)
            .system(size: 16).italic()
            #else
            .footnote
            #endif
        }

        static var metadata: Font {
            #if targetEnvironment(macCatalyst)
            .system(size: 15, weight: .semibold)
            #else
            .caption
            #endif
        }

        static var playButton: Font {
            #if targetEnvironment(macCatalyst)
            .system(size: 18, weight: .semibold)
            #else
            .callout
            #endif
        }

        static var descriptionLineLimit: Int {
            #if targetEnvironment(macCatalyst)
            4
            #else
            3
            #endif
        }

        static func controlHeight(_ layout: ViewLayout) -> CGFloat {
            #if targetEnvironment(macCatalyst)
            52
            #else
            layout.controlHeight
            #endif
        }

        static func buttonSpacing(_ layout: ViewLayout) -> CGFloat {
            #if targetEnvironment(macCatalyst)
            24
            #else
            layout.value(standard: 8, large: 24)
            #endif
        }

        /// The header stacks its parts 10 pt apart, so this tops the gap under the description
        /// up to match the gap under the play button.
        static func descriptionBottomPadding(_ layout: ViewLayout) -> CGFloat {
            #if targetEnvironment(macCatalyst)
            max(0, buttonSpacing(layout) - 10)
            #else
            0
            #endif
        }

        static func actionBarMaxWidth(_ layout: ViewLayout) -> CGFloat {
            #if targetEnvironment(macCatalyst)
            500
            #else
            layout.value(standard: 300, large: 450)
            #endif
        }
    }
}
