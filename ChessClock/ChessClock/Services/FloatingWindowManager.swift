import AppKit
import SwiftUI

/// Manages right-click context menu on the status bar icon and a detached floating panel.
@MainActor
final class FloatingWindowManager: NSObject, NSMenuDelegate {
    static let shared = FloatingWindowManager()

    private var panel: NSPanel?
    private let clockService = ClockService()
    private var eventMonitor: Any?

    private lazy var contextMenu: NSMenu = {
        let menu = NSMenu()

        let floatItem = NSMenuItem(
            title: "Open as Floating Window",
            action: #selector(openFloatingWindow),
            keyEquivalent: ""
        )
        floatItem.target = self
        menu.addItem(floatItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Chess Clock",
            action: #selector(quitApp),
            keyEquivalent: ""
        )
        quitItem.target = self
        menu.addItem(quitItem)

        menu.delegate = self
        return menu
    }()

    private override init() {}

    /// Call once (e.g. in onAppear) to begin watching right-clicks on the status bar icon.
    func setup() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self else { return event }
            // Only intercept events on our own NSStatusBarWindow
            if let window = event.window,
               NSStringFromClass(type(of: window)) == "NSStatusBarWindow" {
                Task { @MainActor in self.showContextMenuOnStatusItem() }
                return nil  // suppress default right-click handling
            }
            return event
        }
    }

    private func showContextMenuOnStatusItem() {
        let sel = NSSelectorFromString("statusItem")
        for window in NSApp.windows {
            guard NSStringFromClass(type(of: window)) == "NSStatusBarWindow",
                  window.responds(to: sel),
                  let item = window.perform(sel)?.takeUnretainedValue() as? NSStatusItem
            else { continue }
            item.menu = contextMenu
            item.button?.performClick(nil)
            return
        }
    }

    // NSMenuDelegate: clear the menu after it closes so left-click still shows the window.
    nonisolated func menuDidClose(_ menu: NSMenu) {
        Task { @MainActor in
            let sel = NSSelectorFromString("statusItem")
            for window in NSApp.windows {
                guard NSStringFromClass(type(of: window)) == "NSStatusBarWindow",
                      window.responds(to: sel),
                      let item = window.perform(sel)?.takeUnretainedValue() as? NSStatusItem
                else { continue }
                item.menu = nil
                return
            }
        }
    }

    @objc private func openFloatingWindow() { showFloatingWindow() }
    @objc private func quitApp() { NSApplication.shared.terminate(nil) }

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

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
