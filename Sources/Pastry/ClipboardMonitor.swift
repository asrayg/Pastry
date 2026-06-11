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
        } else if let png = pngData(from: pb), let fitted = fitToLimit(png) {
            store.add(.image(fitted))
        }
    }

    /// Downscales oversized images (e.g. Retina screenshots) instead of dropping them.
    private func fitToLimit(_ png: Data) -> Data? {
        var data = png
        var attempts = 0
        while data.count > HistoryStore.maxItemBytes, attempts < 4 {
            guard let smaller = downscaled(data, factor: 0.7) else { return nil }
            data = smaller
            attempts += 1
        }
        return data.count <= HistoryStore.maxItemBytes ? data : nil
    }

    private func downscaled(_ data: Data, factor: CGFloat) -> Data? {
        guard let source = NSBitmapImageRep(data: data), let image = NSImage(data: data) else { return nil }
        let width = Int(CGFloat(source.pixelsWide) * factor)
        let height = Int(CGFloat(source.pixelsHigh) * factor)
        guard width > 0, height > 0,
              let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
              ),
              let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        image.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])
    }

    private func pngData(from pb: NSPasteboard) -> Data? {
        if let png = pb.data(forType: .png) { return png }
        guard let tiff = pb.data(forType: .tiff),
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
