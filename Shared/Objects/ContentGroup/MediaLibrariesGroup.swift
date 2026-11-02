//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

#if targetEnvironment(macCatalyst)

/// A row of library tiles, like the "My Media" section of the default Jellyfin app.
struct MediaLibrariesGroup: ContentGroup {

    let id: String = "media-libraries"
    let viewModel: PagingLibraryViewModel<UserViewLibrary> = .init(library: UserViewLibrary(), pageSize: 20)

    var _shouldBeResolved: Bool {
        viewModel.elements.isNotEmpty
    }

    func body(with viewModel: PagingLibraryViewModel<UserViewLibrary>) -> some View {
        MediaLibrariesSection(elements: viewModel.elements.elements)
    }
}

private struct MediaLibrariesSection: View {

    private static let tileWidth: CGFloat = 240

    let elements: [UserViewLibraryElement]

    private var libraryStyle: LibraryStyle {
        LibraryStyle(displayType: .grid, posterDisplayType: .landscape, listColumnCount: 1)
    }

    var body: some View {
        if elements.isNotEmpty {
            ContentGroupSection {
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 16) {
                        ForEach(elements) { element in
                            VStack(alignment: .leading, spacing: 8) {
                                element.makeBody(libraryStyle: libraryStyle, action: nil)
                                    .aspectRatio(16 / 9, contentMode: .fit)

                                Text(element.displayTitle)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                            }
                            .frame(width: Self.tileWidth)
                        }
                    }
                    .edgePadding(.horizontal)
                }
                .scrollIndicators(.hidden)
            } header: {
                Text(L10n.media)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .edgePadding(.horizontal)
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }
}

#endif
