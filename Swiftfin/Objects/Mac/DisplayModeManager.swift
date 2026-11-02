//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreGraphics
import SwiftUI
import UIKit

#if targetEnvironment(macCatalyst)

struct DisplayMode: Identifiable {

    let id: String
    let displayID: CGDirectDisplayID
    let mode: CGDisplayMode

    var isHiDPI: Bool {
        mode.pixelWidth > mode.width
    }

    var title: String {
        let hertz = mode.refreshRate > 0 ? " @ \(Int(mode.refreshRate.rounded())) Hz" : ""
        let scaled = isHiDPI ? " (HiDPI)" : ""
        return "\(mode.width) × \(mode.height)\(hertz)\(scaled)"
    }
}

struct DisplayInfo: Identifiable {

    let id: CGDirectDisplayID
    let name: String
    let modes: [DisplayMode]
    let currentModeID: String?
}

/// Lists and switches the resolution and refresh rate of connected displays, for example a TV.
@MainActor
final class DisplayModeManager: ObservableObject {

    static let shared = DisplayModeManager()

    @Published
    private(set) var displays: [DisplayInfo] = []

    private var observers: [NSObjectProtocol] = []

    private init() {
        refresh()

        let names: [Notification.Name] = [
            UIApplication.didBecomeActiveNotification,
            Notification.Name("NSApplicationDidChangeScreenParametersNotification"),
        ]

        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
    }

    private static func identifier(_ mode: CGDisplayMode) -> String {
        "\(mode.width)x\(mode.height)-\(mode.pixelWidth)x\(mode.pixelHeight)-\(Int(mode.refreshRate.rounded()))"
    }

    func refresh() {
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(UInt32(ids.count), &ids, &count) == .success else { return }

        let options = [kCGDisplayShowDuplicateLowResolutionModes: true] as CFDictionary

        displays = ids.prefix(Int(count)).enumerated().map { offset, displayID in
            let all = (CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode]) ?? []

            var seen = Set<String>()
            let modes = all
                .filter { $0.isUsableForDesktopGUI() }
                .filter { seen.insert(Self.identifier($0)).inserted }
                .sorted {
                    if $0.width != $1.width { return $0.width > $1.width }
                    if $0.height != $1.height { return $0.height > $1.height }
                    return $0.refreshRate > $1.refreshRate
                }
                .map { DisplayMode(id: Self.identifier($0), displayID: displayID, mode: $0) }

            let name = CGDisplayIsBuiltin(displayID) != 0
                ? "Built-in Display"
                : "External Display \(offset)"

            return DisplayInfo(
                id: displayID,
                name: name,
                modes: modes,
                currentModeID: CGDisplayCopyDisplayMode(displayID).map(Self.identifier)
            )
        }
    }

    func apply(_ mode: DisplayMode) {
        var configuration: CGDisplayConfigRef?

        guard CGBeginDisplayConfiguration(&configuration) == .success else { return }

        guard CGConfigureDisplayWithDisplayMode(configuration, mode.displayID, mode.mode, nil) == .success else {
            CGCancelDisplayConfiguration(configuration)
            return
        }

        // `.forSession` reverts to the user's saved resolution when the app quits.
        CGCompleteDisplayConfiguration(configuration, .forSession)

        refresh()
    }
}

#endif
