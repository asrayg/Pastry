import AppKit
import ApplicationServices
import Carbon // for kVK_ANSI_V

enum Paster {
    /// Writes the item to the pasteboard, refocuses the source app, then synthesizes ⌘V.
    /// Falls back to clipboard-only if Accessibility permission hasn't been granted.
    static func paste(_ item: ClipItem, monitor: ClipboardMonitor, into targetApp: NSRunningApplication?) {
        let pb = NSPasteboard.general
        monitor.ignoreNextChange = true
        switch item.content {
        case .text(let s):
            pb.clearContents()
            pb.setString(s, forType: .string)
        case .image(let data):
            pb.setImagePNG(data)
        }

        guard AXIsProcessTrusted() else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let app = targetApp, !app.isActive {
                app.activate(options: .activateIgnoringOtherApps)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                sendCmdV()
            }
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

extension NSPasteboard {
    /// Writes an image as both TIFF and PNG — apps disagree on which they read
    /// (TextEdit/Pages/Mail want TIFF, web apps tend to want PNG).
    func setImagePNG(_ png: Data) {
        declareTypes([.tiff, .png], owner: nil)
        if let tiff = NSImage(data: png)?.tiffRepresentation {
            setData(tiff, forType: .tiff)
        }
        setData(png, forType: .png)
    }
}
