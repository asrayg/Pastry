import AppKit
import SwiftUI
import ApplicationServices

final class PanelViewModel: ObservableObject {
    @Published var selection: Int = 0
    @Published var presentedAt = Date()
}

/// Borderless panel that can take keyboard focus without activating the app,
/// so the app you're pasting into never loses focus.
final class HistoryPanel: NSPanel {
    var onKeyDown: ((NSEvent) -> Bool)?

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if onKeyDown?(event) == true { return }
        super.keyDown(with: event)
    }
}

final class PanelController {
    static let panelSize = NSSize(width: 360, height: 460)

    private let store: HistoryStore
    private let monitor: ClipboardMonitor
    private let vm = PanelViewModel()
    private var panel: HistoryPanel?
    // The app that was frontmost when the panel opened — Cmd+V must go there.
    private var sourceApp: NSRunningApplication?

    init(store: HistoryStore, monitor: ClipboardMonitor) {
        self.store = store
        self.monitor = monitor
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func show() {
        sourceApp = NSWorkspace.shared.frontmostApplication
        let panel = ensurePanel()
        vm.selection = 0
        vm.presentedAt = Date()
        position(panel)
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func ensurePanel() -> HistoryPanel {
        if let panel { return panel }

        let panel = HistoryPanel(
            contentRect: NSRect(origin: .zero, size: Self.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.onKeyDown = { [weak self] event in
            self?.handleKey(event) ?? false
        }

        let view = HistoryView(
            store: store,
            vm: vm,
            onPaste: { [weak self] item in self?.paste(item) },
            onTogglePin: { [weak self] item in self?.store.togglePin(item.id) },
            onDelete: { [weak self] item in self?.delete(item) },
            onClearAll: { [weak self] in self?.store.clearAll() }
        )
        panel.contentView = NSHostingView(rootView: view)

        // Dismiss when focus moves elsewhere, like the Win+V flyout.
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.hide()
        }

        self.panel = panel
        return panel
    }

    private func position(_ panel: HistoryPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }

        var origin = NSPoint(x: mouse.x - 20, y: mouse.y - Self.panelSize.height - 8)
        origin.x = min(max(origin.x, visible.minX + 8), visible.maxX - Self.panelSize.width - 8)
        origin.y = min(max(origin.y, visible.minY + 8), visible.maxY - Self.panelSize.height - 8)
        panel.setFrameOrigin(origin)
    }

    // MARK: - Actions

    private func paste(_ item: ClipItem) {
        let target = sourceApp
        hide()
        Paster.paste(item, monitor: monitor, into: target)
    }

    private func delete(_ item: ClipItem) {
        store.delete(item.id)
        clampSelection()
    }

    private func clampSelection() {
        vm.selection = max(0, min(vm.selection, store.items.count - 1))
    }

    private var selectedItem: ClipItem? {
        store.items.indices.contains(vm.selection) ? store.items[vm.selection] : nil
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 126: // up
            vm.selection = max(0, vm.selection - 1)
            return true
        case 125: // down
            vm.selection = min(max(0, store.items.count - 1), vm.selection + 1)
            return true
        case 36, 76: // return / keypad enter
            if let item = selectedItem { paste(item) }
            return true
        case 53: // esc
            hide()
            return true
        case 51, 117: // delete / forward delete
            if let item = selectedItem { delete(item) }
            return true
        case 35: // p — pin/unpin
            if let item = selectedItem { store.togglePin(item.id) }
            return true
        default:
            return false
        }
    }
}
