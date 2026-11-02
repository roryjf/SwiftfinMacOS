//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// The last subtitle choice made in the player, restored when the next item starts.
enum SubtitlePreference {

    private static let enabledKey = "swiftfin.player.subtitlesEnabled"
    private static let languageKey = "swiftfin.player.subtitleLanguage"

    /// `nil` until the user has made a choice.
    static var isEnabled: Bool? {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool
    }

    static var language: String? {
        UserDefaults.standard.string(forKey: languageKey)
    }

    static func record(enabled: Bool? = nil, language: String? = nil) {
        let defaults = UserDefaults.standard

        if let enabled {
            defaults.set(enabled, forKey: enabledKey)
        }

        if let language, !language.isEmpty {
            defaults.set(language, forKey: languageKey)
        }
    }
}
