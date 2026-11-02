//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

private struct ItemActionButtonLabelStyle: LabelStyle {

    @AdaptiveLayout
    private var viewLayout

    @Environment(\.isSelected)
    private var isSelected

    var activeColor: Color?

    private var iconSize: CGFloat {
        #if targetEnvironment(macCatalyst)
        24
        #else
        viewLayout.value(standard: 24, large: 40)
        #endif
    }

    private var iconPadding: CGFloat {
        #if targetEnvironment(macCatalyst)
        14
        #else
        viewLayout.value(standard: 8, large: 16)
        #endif
    }

    private var tint: Color {
        guard isSelected, let activeColor else {
            return .gray.opacity(0.15)
        }

        return activeColor
    }

    private var foregroundColor: Color {
        guard isSelected, let activeColor else {
            return .primary
        }

        return activeColor.overlayColor
    }

    func makeBody(configuration: Configuration) -> some View {
        Label(configuration)
            .labelStyle(.iconOnly)
            .font(.system(size: iconSize * 0.8))
            .frame(width: iconSize, height: iconSize)
            .padding(iconPadding)
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
            .backport
            .glassEffect(
                .regular.selection(
                    tint: tint,
                    foregroundColor: foregroundColor
                ),
                in: .capsule
            )
    }
}

struct ItemActionButtons: View {

    @AdaptiveLayout
    private var viewLayout

    static let maximumButtons = 4

    @ObservedObject
    var provider: ItemContentGroupProvider

    let buttons: [ItemActionButton]
    let overflowButtons: [ItemActionButton]
    let menuButtons: [ItemActionButton]
    let focusedButton: FocusState<String?>.Binding

    private static func hasTrailers(
        for provider: ItemContentGroupProvider,
        enabledTrailers: TrailerSelection
    ) -> Bool {
        if enabledTrailers.contains(.local), provider.localTrailers.isNotEmpty {
            return true
        }

        if enabledTrailers.contains(.external), provider.item.remoteTrailers?.isNotEmpty == true {
            return true
        }

        return false
    }

    private static func isAvailable(
        _ button: ItemActionButton,
        for provider: ItemContentGroupProvider,
        enabledTrailers: TrailerSelection
    ) -> Bool {
        switch button {
        case .played:
            provider.item.canBePlayed
        case .favorited:
            provider.item.canBeFavorited
        case .trailers:
            hasTrailers(for: provider, enabledTrailers: enabledTrailers)
        case .playback:
            provider.item.presentPlayButton && provider.playbackIntent?.mediaSource != nil
        case .shuffle:
            provider.item.canShuffle
        case .record:
            provider.item.canBeRecorded
        case .refresh:
            provider.item.canEditMetadata
        case .subtitles:
            provider.item.canEditSubtitles
        case .delete:
            provider.item.canDelete == true
        #if os(iOS)
        case .editMetadata:
            provider.item.canEditMetadata
        #endif
        }
    }

    private static func availableButtons(
        _ buttons: [ItemActionButton],
        for provider: ItemContentGroupProvider,
        enabledTrailers: TrailerSelection
    ) -> [ItemActionButton] {
        buttons.filter {
            isAvailable($0, for: provider, enabledTrailers: enabledTrailers)
        }
    }

    static func resolvedButtons(
        bar: [ItemActionButton],
        menu: [ItemActionButton],
        for provider: ItemContentGroupProvider,
        enabledTrailers: TrailerSelection
    ) -> (visible: [ItemActionButton], overflow: [ItemActionButton], menu: [ItemActionButton]) {
        let bar = availableButtons(bar, for: provider, enabledTrailers: enabledTrailers)
        let menu = availableButtons(menu, for: provider, enabledTrailers: enabledTrailers)

        let hasBarMenu = ViewLayout.platformDefault.isLarge && (menu.isNotEmpty || bar.count > maximumButtons)
        let visible = Array(bar.prefix(hasBarMenu ? maximumButtons - 1 : maximumButtons))
        let overflow = Array(bar.dropFirst(visible.count))

        return (
            visible: visible,
            overflow: overflow,
            menu: menu.subtracting(overflow)
        )
    }

    static func view(for button: ItemActionButton) -> some View {
        Group {
            switch button {
            case .played:
                Played()
            case .favorited:
                Favorited()
            case .trailers:
                Trailers()
            case .playback:
                Playback()
            case .shuffle:
                Shuffle()
            case .record:
                Record()
            case .refresh:
                Refresh()
            case .subtitles:
                Subtitles()
            case .delete:
                Delete()
            #if os(iOS)
            case .editMetadata:
                Edit()
            #endif
            }
        }
        .symbolRenderingMode(.monochrome)
        .foregroundStyle(.primary, .secondary)
    }

    var body: some View {
        let hasBarMenu = viewLayout.isLarge && (overflowButtons.isNotEmpty || menuButtons.isNotEmpty)

        if buttons.isNotEmpty || hasBarMenu {
            HStack(alignment: .center, spacing: ItemView.Typography.buttonSpacing(viewLayout)) {
                ForEach(buttons) { button in
                    Self.view(for: button)
                        .labelStyle(ItemActionButtonLabelStyle(activeColor: button.activeColor))
                        .focused(focusedButton, equals: button.id)
                }

                if hasBarMenu {
                    Menu {
                        MenuContent(
                            provider: provider,
                            buttons: overflowButtons,
                            menuButtons: menuButtons
                        )
                    } label: {
                        Label(L10n.menu, systemImage: "ellipsis")
                    }
                    .menuStyle(.button)
                    .labelStyle(ItemActionButtonLabelStyle())
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.primary, .secondary)
                    .focused(focusedButton, equals: ItemView.Component.menu)
                }
            }
            .frame(height: ItemView.Typography.controlHeight(viewLayout))
            .environmentObject(provider)
            .buttonBorderShape(.capsule)
            .buttonStyle(BasicHoverButtonStyle())
            .font(.title3)
            .fontWeight(.semibold)
        }
    }
}

extension ItemActionButtons {

    struct Configuration: DynamicProperty {

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        @Default(.Customization.itemBarActionButtons)
        private var barActionButtons
        @Default(.Customization.itemMenuActionButtons)
        private var menuActionButtons

        func resolvedButtons(
            for provider: ItemContentGroupProvider
        ) -> (visible: [ItemActionButton], overflow: [ItemActionButton], menu: [ItemActionButton]) {
            ItemActionButtons.resolvedButtons(
                bar: barActionButtons,
                menu: menuActionButtons,
                for: provider,
                enabledTrailers: enabledTrailers
            )
        }
    }

    struct MenuContent: View {

        @ObservedObject
        var provider: ItemContentGroupProvider

        let buttons: [ItemActionButton]
        let menuButtons: [ItemActionButton]

        #if targetEnvironment(macCatalyst)
        private func section(_ group: [ItemActionButton]) -> some View {
            let items = (buttons + menuButtons).filter { group.contains($0) }

            return Group {
                if items.isNotEmpty {
                    Section {
                        ForEach(items, content: ItemActionButtons.view(for:))
                    }
                }
            }
        }
        #endif

        var body: some View {
            Group {
                #if targetEnvironment(macCatalyst)
                // Grouped by purpose, with destructive actions last.
                section([.playback, .shuffle, .trailers, .record])
                section([.played, .favorited])
                section([.editMetadata, .refresh, .subtitles])
                section([.delete])
                #else
                ForEach(
                    buttons,
                    content: ItemActionButtons.view(for:)
                )

                if buttons.isNotEmpty, menuButtons.isNotEmpty {
                    Divider()
                }

                ForEach(
                    menuButtons,
                    content: ItemActionButtons.view(for:)
                )
                #endif
            }
            .environmentObject(provider)
            .withViewContext(.isInMenu)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary)
        }
    }
}
