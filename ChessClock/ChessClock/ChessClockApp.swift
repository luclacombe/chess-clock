//
//  ChessClockApp.swift
//  ChessClock
//
//  Created by Luc Lacombe on 2/20/26.
//

import SwiftUI
import AppKit

@main
struct ChessClockApp: App {
    @StateObject private var clockService = ClockService()
    private let hotkeyService = HotkeyService()

    var body: some Scene {
        // Primary: window-style chess clock
        MenuBarExtra {
            ClockView(clockService: clockService)
                .onAppear { hotkeyService.register() }
        } label: {
            Image(systemName: "crown.fill")
        }
        .menuBarExtraStyle(.window)

        // Secondary: menu-style for context actions (ellipsis icon)
        MenuBarExtra {
            Button("Open as Floating Window") {
                FloatingWindowManager.shared.showFloatingWindow()
            }
            Divider()
            Button("Quit Chess Clock") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }
}
