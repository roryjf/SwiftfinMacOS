//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import OSLog
import SwiftUI
import UIKit

#if targetEnvironment(macCatalyst)

/// Access to the hosting AppKit window, which Mac Catalyst doesn't expose directly.
/// Resolved at runtime so the app doesn't need an AppKit bundle.
@MainActor
enum MacWindow {

    private static let fullScreenMask: UInt = 1 << 14

    private static let logger = Logger(subsystem: "com.roryjf.swiftfin", category: "MacWindow")

    /// Tracked from window notifications, in case the style mask can't be read.
    private static var observedFullScreen = false
    private static var observers: [NSObjectProtocol] = []

    private static var application: NSObject? {
        guard let appClass = NSClassFromString("NSApplication") else {
            logger.error("NSApplication is unavailable")
            return nil
        }

        return (appClass as AnyObject)
            .perform(NSSelectorFromString("sharedApplication"))?
            .takeUnretainedValue() as? NSObject
    }

    private static var window: NSObject? {
        guard let application else { return nil }

        return (application.value(forKey: "keyWindow") as? NSObject)
            ?? (application.value(forKey: "mainWindow") as? NSObject)
            ?? (application.value(forKey: "windows") as? [NSObject])?.first
    }

    static var isFullScreen: Bool {
        if let mask = window?.value(forKey: "styleMask") as? UInt {
            return mask & fullScreenMask != 0
        }

        return observedFullScreen
    }

    static func toggleFullScreen() {
        let selector = NSSelectorFromString("toggleFullScreen:")

        if let window {
            logger.debug("Toggling full screen on the window")
            _ = window.perform(selector, with: nil)
        } else if let application {
            logger.debug("No window found, sending toggleFullScreen: through the responder chain")
            _ = application.perform(NSSelectorFromString("sendAction:to:from:"), with: selector, with: nil)
        } else {
            logger.error("Unable to toggle full screen")
        }
    }

    private static func observeFullScreen() {
        guard observers.isEmpty else { return }

        let center = NotificationCenter.default

        observers = [
            ("NSWindowDidEnterFullScreenNotification", true),
            ("NSWindowDidExitFullScreenNotification", false),
        ].map { name, value in
            center.addObserver(forName: Notification.Name(name), object: nil, queue: .main) { _ in
                observedFullScreen = value
            }
        }
    }

    static func exitFullScreen() {
        guard isFullScreen else { return }
        toggleFullScreen()
    }

    /// Sensible window bounds so the layout never collapses below a usable size.
    static func configureScenes() {
        observeFullScreen()

        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            scene.sizeRestrictions?.minimumSize = CGSize(width: 900, height: 560)
        }
    }
}

extension View {

    func configuresMacWindow() -> some View {
        onAppear { MacWindow.configureScenes() }
    }
}

#else

extension View {

    func configuresMacWindow() -> some View {
        self
    }
}

#endif
