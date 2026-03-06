import AppKit
import SwiftUI

// MARK: - BorderlessPanel

/// Borderless NSPanel subclass that can become key/main for keyboard events.
private class BorderlessPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - TitleBarDragArea

/// NSView that initiates a window drag on mouse-down.
/// Placed as the base layer of the floating window's title bar; SwiftUI buttons
/// overlaid on top capture their own clicks first — everything else drags.
private struct TitleBarDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> _DragView { _DragView() }
    func updateNSView(_ nsView: _DragView, context: Context) {}

    final class _DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

// MARK: - FloatingWindowContent

/// Wraps ClockView with a hover-visible title bar for drag + close.
private struct FloatingWindowContent: View {
    let clockService: ClockService
    let onClose: () -> Void
    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .top) {
            // Opaque background — soft white, visible in corners and semi-transparent areas
            Color(white: 0.93)

            ClockView(clockService: clockService)

            // Title bar — slides down from top on hover
            if isHovering {
                titleBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.outer))
        .onHover { hovering in
            withAnimation(ChessClockAnimation.fast) { isHovering = hovering }
        }
    }

    private var titleBar: some View {
        TitleBarDragArea()
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(
                ZStack {
                    Color.black.opacity(0.50)
                    VStack { Spacer(); Color.white.opacity(0.08).frame(height: 0.5) }
                }
                .allowsHitTesting(false)
            )
            .overlay(alignment: .leading) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 22, height: 22)
                        .background(.black.opacity(0.45), in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                .padding(.leading, 10)
            }
            .overlay {
                // Drag grip indicator
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.white.opacity(0.30))
                            .frame(width: 4, height: 4)
                    }
                }
                .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
    }
}

// MARK: - FloatingWindowManager

/// Manages right-click context menu on the status bar icon and a detached floating panel.
@MainActor
final class FloatingWindowManager: NSObject, NSMenuDelegate {
    static let shared = FloatingWindowManager()

    private var panel: BorderlessPanel?
    private var clockService: ClockService?
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
    func setup(clockService: ClockService) {
        self.clockService = clockService
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
        guard let clockService else { return }

        let p = BorderlessPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.level = .floating
        p.isMovableByWindowBackground = false
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.hidesOnDeactivate = false
        p.collectionBehavior.insert(.canJoinAllSpaces)
        p.isReleasedWhenClosed = false

        let content = FloatingWindowContent(
            clockService: clockService,
            onClose: { [weak p] in p?.close() }
        )
        p.contentView = NSHostingView(rootView: content)
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
