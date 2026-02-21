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

    var body: some Scene {
        MenuBarExtra {
            ClockView(clockService: clockService)
        } label: {
            Image(systemName: "crown.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
