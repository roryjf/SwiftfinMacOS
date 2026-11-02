//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

#if targetEnvironment(macCatalyst)

/// The home screen with a search field in the toolbar. Results replace the home content while searching.
struct MacHomeView<Provider: ContentGroupProvider>: View {

    @State
    private var query = ""

    let provider: Provider

    private var isSearching: Bool {
        query.trimmingCharacters(in: .whitespaces).isNotEmpty
    }

    var body: some View {
        // Home stays mounted underneath, so clearing the search doesn't reload it.
        ContentGroupView(provider: provider)
            .overlay {
                if isSearching {
                    SearchView(externalQuery: $query)
                        .background(Color(uiColor: .systemBackground))
                }
            }
            .searchable(text: $query, prompt: L10n.search)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isSearching {
                        Button {
                            query = ""
                        } label: {
                            Label(L10n.home, systemImage: "chevron.left")
                        }
                        .keyboardShortcut("[", modifiers: .command)
                        .help(L10n.home)
                    }
                }
            }
    }
}

#endif
