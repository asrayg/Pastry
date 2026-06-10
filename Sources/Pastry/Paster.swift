import AppKit
import ApplicationServices
import Carbon // for kVK_ANSI_V

enum Paster {
    /// Puts the item on the pasteboard, then synthesizes ⌘V into the frontmost app.
    /// Falls back to copy-only if accessibility permission hasn't been granted.
    static func paste(_ item: ClipItem, monitor: ClipboardMonitor) {
        let pb = NSPasteboard.general
        monitor.ignoreNextChange = true
        pb.clearContents()
        switch item.content {
        case .text(let s):
            pb.setString(s, forType: .string)
        case .image(let data):
            pb.setData(data, forType: .png)
        }

        guard AXIsProcessTrusted() else { return }
        // Small delay so the panel has fully dismissed and focus is back on the target app.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            sendCmdV()
        }
    }

    private static func sendCmdV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKey = CGKeyCode(kVK_ANSI_V)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false) else { return }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
