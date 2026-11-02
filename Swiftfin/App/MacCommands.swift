//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct MacCommands: Commands {

    #if targetEnvironment(macCatalyst)
    @ObservedObject
    private var displayModes = DisplayModeManager.shared
    #endif

    var body: some Commands {
        #if targetEnvironment(macCatalyst)
        CommandGroup(after: .toolbar) {
            Menu("Display Resolution") {
                ForEach(displayModes.displays) { display in
                    Section(display.name) {
                        ForEach(display.modes) { mode in
                            Toggle(
                                mode.title,
                                isOn: Binding(
                                    get: { display.currentModeID == mode.id },
                                    set: { _ in displayModes.apply(mode) }
                                )
                            )
                        }
                    }
                }

                Divider()

                Button("Refresh Displays") {
                    displayModes.refresh()
                }
            }
        }
        #endif
    }
}
