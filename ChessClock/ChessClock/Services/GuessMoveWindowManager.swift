import AppKit
import SwiftUI

/// Opens and manages the floating "Guess Move" panel.
@MainActor
final class GuessMoveWindowManager {
    static let shared = GuessMoveWindowManager()
    private var panel: NSPanel?

    private init() {}

    func open(state: ClockState, guessService: GuessService) {
        if let existing = panel, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 460),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Guess the Move"
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(
            rootView: GuessMoveView(state: state, guessService: guessService)
        )
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }
}
