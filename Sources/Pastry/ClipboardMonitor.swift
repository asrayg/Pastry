import AppKit

final class ClipboardMonitor {
    private let store: HistoryStore
    private var timer: Timer?
    private var changeCount = NSPasteboard.general.changeCount

    /// Set before writing to the pasteboard ourselves so the write isn't re-recorded.
    var ignoreNextChange = false

    // Conventions used by password managers etc. to mark sensitive/transient content.
    private static let skippedTypes: [NSPasteboard.PasteboardType] = [
        NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"),
        NSPasteboard.PasteboardType("org.nspasteboard.TransientType"),
    ]

    init(store: HistoryStore) {
        self.store = store
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.check()
        }
    }

    private func check() {
        let pb = NSPasteboard.general
        guard pb.changeCount != changeCount else { return }
        changeCount = pb.changeCount

        if ignoreNextChange {
            ignoreNextChange = false
            return
        }

        if let types = pb.types, !Set(types).isDisjoint(with: Self.skippedTypes) { return }

        if let s = pb.string(forType: .string), !s.isEmpty {
            guard s.utf8.count <= HistoryStore.maxItemBytes else { return }
            store.add(.text(s))
        } else if let png = pngData(from: pb) {
            guard png.count <= HistoryStore.maxItemBytes else { return }
            store.add(.image(png))
        }
    }

    private func pngData(from pb: NSPasteboard) -> Data? {
        if let png = pb.data(forType: .png) { return png }
        guard let tiff = pb.data(forType: .tiff),
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
