//
//  HotkeyService.swift
//  ChessClock
//
//  Created by Luc Lacombe on 2/21/26.
//

import Carbon
import AppKit

final class HotkeyService {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    func register() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind:  UInt32(kEventHotKeyPressed)
        )
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                guard let ptr = userData else { return OSStatus(eventNotHandledErr) }
                let svc = Unmanaged<HotkeyService>.fromOpaque(ptr).takeUnretainedValue()
                svc.toggle()
                return noErr
            },
            1, &eventType, selfPtr, &eventHandlerRef
        )

        // Option + Space: kVK_Space = 0x31, optionKey modifier = 2048
        let sig = "CHES".unicodeScalars.reduce(0 as UInt32) { ($0 << 8) | UInt32($1.value) }
        var hotKeyID = EventHotKeyID(signature: sig, id: 1)
        RegisterEventHotKey(UInt32(kVK_Space), UInt32(optionKey),
                            hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        hotKeyRef.map { UnregisterEventHotKey($0) }
        eventHandlerRef.map { RemoveEventHandler($0) }
    }

    // Locate the NSStatusItem managed by SwiftUI's MenuBarExtra via the
    // NSStatusBarWindow that hosts it, then simulate a button click to
    // toggle the popover/window. This avoids the removed
    // NSStatusBar.system.statusItems property (removed in macOS 26 SDK).
    private func toggle() {
        DispatchQueue.main.async {
            let sel = NSSelectorFromString("statusItem")
            for window in NSApp.windows {
                guard NSStringFromClass(type(of: window)) == "NSStatusBarWindow",
                      window.responds(to: sel),
                      let item = window.perform(sel)?.takeUnretainedValue() as? NSStatusItem
                else { continue }
                item.button?.performClick(nil)
                return
            }
        }
    }

    deinit { unregister() }
}
