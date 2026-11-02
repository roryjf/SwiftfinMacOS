//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

#if os(iOS)
private struct HoverHighlightModifier<S: InsettableShape>: ViewModifier {

    @State
    private var isHovering = false

    let shape: S
    let tint: Color
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .contentShape(shape)
            .overlay {
                shape
                    .fill(tint.opacity(isHovering ? opacity : 0))
                    .allowsHitTesting(false)
            }
            .onHover { isHovering = $0 }
            .animation(.easeOut(duration: 0.12), value: isHovering)
    }
}
#endif

extension View {

    /// Highlights the view while a pointer hovers over it.
    @ViewBuilder
    func hoverHighlight<S: InsettableShape>(
        _ shape: S = RoundedRectangle(cornerRadius: 8),
        tint: Color = .primary,
        opacity: Double = 0.12
    ) -> some View {
        #if os(iOS)
        modifier(HoverHighlightModifier(shape: shape, tint: tint, opacity: opacity))
        #else
        self
        #endif
    }
}
