//
//  ChessClockApp.swift
//  ChessClock
//
//  Created by Luc Lacombe on 2/20/26.
//

import SwiftUI

@main
struct ChessClockApp: App {
    @StateObject private var clockService = ClockService()
    private let hotkeyService = HotkeyService()

    var body: some Scene {
        // Register hotkey and right-click monitor at app launch, not on first
        // popover open — otherwise right-click context menu is unavailable
        // until the user left-clicks the icon at least once.
        let _ = hotkeyService.register()
        let _ = FloatingWindowManager.shared.setup(clockService: clockService)
        MenuBarExtra {
            ClockView(clockService: clockService)
        } label: {
            Image(systemName: "crown.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
