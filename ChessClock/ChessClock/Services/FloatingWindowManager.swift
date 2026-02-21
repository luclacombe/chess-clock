import AppKit
import SwiftUI

/// Manages a floating NSPanel that shows a separate Chess Clock window.
/// The panel has its own ClockService instance (same game, independent timer).
@MainActor
final class FloatingWindowManager {
    static let shared = FloatingWindowManager()
    private var panel: NSPanel?
    private let clockService = ClockService()

    private init() {}

    func showFloatingWindow() {
        if let existing = panel, existing.isVisible {
            existing.orderFront(nil)
            return
        }
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 324, height: 400),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.level = .floating
        p.title = "Chess Clock"
        p.isReleasedWhenClosed = false
        p.contentView = NSHostingView(rootView: ClockView(clockService: clockService))
        p.center()
        p.makeKeyAndOrderFront(nil)
        panel = p
    }
}
