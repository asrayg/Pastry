import AppKit
import Darwin

/// Watches the screenshot save folder for new captures (⌘⇧3 / ⌘⇧4 save to disk,
/// not the clipboard) and puts them on the clipboard — so the next ⌘V pastes them
/// and the clipboard monitor records them into history, matching Win+Shift+S.
///
/// Uses a kqueue directory watch + the screenshot xattr rather than Spotlight,
/// which isn't reliable on every machine.
final class ScreenshotWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var seenNames = Set<String>()

    private var directory: URL {
        if let loc = CFPreferencesCopyAppValue(
            "location" as CFString,
            "com.apple.screencapture" as CFString
        ) as? String {
            return URL(fileURLWithPath: (loc as NSString).expandingTildeInPath, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    }

    func start() {
        let dir = directory
        let fd = open(dir.path, O_EVTONLY)
        guard fd >= 0 else { return }

        if let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path) {
            seenNames.formUnion(names)
        }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .main
        )
        src.setEventHandler { [weak self] in self?.scan() }
        src.setCancelHandler { close(fd) }
        src.resume()
        source = src
    }

    private func scan() {
        let dir = directory
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }
        for name in names where !seenNames.contains(name) {
            seenNames.insert(name)
            guard !name.hasPrefix(".") else { continue }
            let url = dir.appendingPathComponent(name)
            guard isScreenshot(url) else { continue }
            // Give the capture a beat to finish writing before reading it.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.publish(url)
            }
        }
    }

    private func isScreenshot(_ url: URL) -> Bool {
        getxattr(url.path, "com.apple.metadata:kMDItemIsScreenCapture", nil, 0, 0, 0) > 0
    }

    private func publish(_ url: URL) {
        guard let data = try? Data(contentsOf: url), !data.isEmpty else { return }
        let png: Data?
        if url.pathExtension.lowercased() == "png" {
            png = data
        } else {
            png = NSBitmapImageRep(data: data)?.representation(using: .png, properties: [:])
        }
        guard let png else { return }
        NSPasteboard.general.setImagePNG(png)
    }
}
