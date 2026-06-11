import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var loginItem: NSMenuItem!
    private var accessibilityItem: NSMenuItem!

    private let store = HistoryStore()
    private let hotKey = HotKey()
    private let screenshotWatcher = ScreenshotWatcher()
    private var monitor: ClipboardMonitor!
    private var panelController: PanelController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor = ClipboardMonitor(store: store)
        panelController = PanelController(store: store, monitor: monitor)

        monitor.start()
        screenshotWatcher.start()
        hotKey.handler = { [weak self] in self?.panelController.toggle() }
        hotKey.register()

        setupStatusItem()
        promptForAccessibilityIfNeeded()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "doc.on.clipboard",
            accessibilityDescription: "Pastry"
        )

        let menu = NSMenu()
        menu.delegate = self

        let showItem = NSMenuItem(
            title: "Show Clipboard History",
            action: #selector(showHistory),
            keyEquivalent: "v"
        )
        showItem.keyEquivalentModifierMask = [.command, .shift]
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(.separator())

        let clearItem = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())

        accessibilityItem = NSMenuItem(title: "Enable Auto-Paste…", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        accessibilityItem.target = self
        menu.addItem(accessibilityItem)

        menu.addItem(.separator())

        loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: "About Pastry", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem(title: "Quit Pastry", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off

        if AXIsProcessTrusted() {
            accessibilityItem.title = "Auto-Paste: On ✓"
            accessibilityItem.action = nil // greyed out when already granted
        } else {
            accessibilityItem.title = "Enable Auto-Paste… (required)"
            accessibilityItem.action = #selector(openAccessibilitySettings)
        }
    }

    @objc private func showHistory() {
        panelController.show()
    }

    @objc private func clearHistory() {
        store.clearAll()
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func toggleLoginItem() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Failed to toggle login item: \(error)")
        }
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    private func promptForAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "Pastry needs Accessibility access to auto-paste"
            alert.informativeText = """
                Without it, Pastry copies your selection to the clipboard but you'll need to press ⌘V yourself.

                To enable:
                1. Click "Open Settings" below
                2. Click the lock to make changes
                3. Find Pastry in the list and turn it ON
                4. If Pastry isn't listed, click + and navigate to /Applications/Pastry.app
                """
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Not Now")
            alert.alertStyle = .warning
            if alert.runModal() == .alertFirstButtonReturn {
                self.openAccessibilitySettings()
            }
        }
    }
}
