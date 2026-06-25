// App Store screenshot harness for Pastry.
//
// Reuses the app's real HistoryView + themes, seeds realistic demo clipboard
// items, renders the actual frosted-glass panel over a branded gradient with a
// marketing headline, and captures one 2880x1800 PNG per shot.
//
// Compiled together with the app's view sources (NOT main.swift / AppDelegate)
// by tools/screenshots/run.sh. The two shims below stand in for the parts of
// PanelController.swift that HistoryView needs, so we don't have to drag in the
// clipboard/paste/hotkey machinery.

import AppKit
import SwiftUI
import Combine

// MARK: - Shims for HistoryView's dependencies (mirrors PanelController.swift)

enum PanelController { static let panelSize = NSSize(width: 360, height: 460) }

final class PanelViewModel: ObservableObject {
    @Published var selection: Int = 0
    @Published var presentedAt = Date()
}

// MARK: - Shot definitions

struct Shot {
    let theme: PastryTheme
    let headline: String
    let subhead: String
    let file: String
}

let shots: [Shot] = [
    Shot(theme: .sunset,
         headline: "Everything you've copied,\none keystroke away",
         subhead: "Press ⌘⇧V anywhere to bring back your clipboard history.",
         file: "01-history.png"),
    Shot(theme: .ocean,
         headline: "Pin the things\nyou reuse",
         subhead: "Pinned items stay at the top and never expire.",
         file: "02-pins.png"),
    Shot(theme: .forest,
         headline: "Text, images,\nand screenshots",
         subhead: "Snap a screenshot and it's ready to paste instantly.",
         file: "03-images.png"),
    Shot(theme: .candy,
         headline: "Five beautiful\nthemes",
         subhead: "Match Pastry to your desktop in a tap.",
         file: "04-themes.png"),
    Shot(theme: .mono,
         headline: "Private\nby design",
         subhead: "Your clipboard never leaves your Mac.",
         file: "05-privacy.png"),
]

// MARK: - Demo content

func demoImageData() -> Data {
    let size = NSSize(width: 520, height: 300)
    let image = NSImage(size: size)
    image.lockFocus()
    let grad = NSGradient(colors: [
        NSColor(calibratedRed: 0.40, green: 0.62, blue: 0.98, alpha: 1),
        NSColor(calibratedRed: 0.65, green: 0.45, blue: 0.95, alpha: 1),
    ])!
    grad.draw(in: NSRect(origin: .zero, size: size), angle: -55)
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 34, weight: .semibold),
        .foregroundColor: NSColor.white.withAlphaComponent(0.95),
        .paragraphStyle: para,
    ]
    let text = "Design review\nmockup.png" as NSString
    let textSize = text.size(withAttributes: attrs)
    text.draw(in: NSRect(x: 0, y: (size.height - textSize.height) / 2,
                         width: size.width, height: textSize.height),
              withAttributes: attrs)
    image.unlockFocus()
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return Data() }
    return png
}

func demoItems() -> [ClipItem] {
    func make(_ content: ClipContent, _ secondsAgo: TimeInterval, pinned: Bool = false) -> ClipItem {
        var item = ClipItem(content: content)
        item.copiedAt = Date(timeIntervalSinceNow: -secondsAgo)
        item.pinned = pinned
        return item
    }

    return [
        make(.text("https://github.com/asray/pastry"), 45, pinned: true),
        make(.text("asraygopa@gmail.com"), 600, pinned: true),
        make(.text("func paste() {\n    NSPasteboard.general.clearContents()\n    NSPasteboard.general.setString(text, forType: .string)\n}"), 120),
        make(.image(demoImageData()), 240),
        make(.text("Standup at 10:30 — share the Q3 roadmap link"), 360),
        make(.text("npm install && npm run build"), 900),
        make(.text("The quick brown fox jumps over the lazy dog."), 1500),
        make(.text("1600 Amphitheatre Parkway, Mountain View, CA 94043"), 2400),
        make(.text("#FF9E6B"), 3600),
    ]
}

// MARK: - Background (gradient + marketing headline)

final class ShotModel: ObservableObject {
    @Published var theme: PastryTheme = .sunset
    @Published var headline: String = ""
    @Published var subhead: String = ""
}

struct ShotBackground: View {
    @ObservedObject var model: ShotModel
    let height: CGFloat

    var body: some View {
        ZStack {
            model.theme.gradient.ignoresSafeArea()
            // Soft darkening so white text stays legible across all themes.
            LinearGradient(colors: [.black.opacity(0.18), .clear],
                           startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text(model.headline)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                Text(model.subhead)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .opacity(0.92)
                Spacer()
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.22), radius: 8, y: 2)
            .padding(.top, height * 0.085)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

// MARK: - Capture helpers

func spin(_ seconds: TimeInterval) {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: seconds))
}

@discardableResult
func run(_ launchPath: String, _ args: [String]) -> Int32 {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: launchPath)
    p.arguments = args
    try? p.run()
    p.waitUntilExit()
    return p.terminationStatus
}

// MARK: - Seeding (back up the user's real history, restore afterwards)

let historyURL: URL = {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return base.appendingPathComponent("Pastry/history.json")
}()

func seedHistory() -> URL? {
    let fm = FileManager.default
    try? fm.createDirectory(at: historyURL.deletingLastPathComponent(),
                            withIntermediateDirectories: true)
    var backup: URL? = nil
    if fm.fileExists(atPath: historyURL.path) {
        let b = historyURL.appendingPathExtension("screenshot-backup")
        try? fm.removeItem(at: b)
        try? fm.copyItem(at: historyURL, to: b)
        backup = b
    }
    let data = try! JSONEncoder().encode(demoItems())
    try! data.write(to: historyURL, options: .atomic)
    return backup
}

func restoreHistory(_ backup: URL?) {
    let fm = FileManager.default
    if let backup {
        try? fm.removeItem(at: historyURL)
        try? fm.moveItem(at: backup, to: historyURL)
    } else {
        try? fm.removeItem(at: historyURL)
    }
}

// MARK: - Runner

final class Runner: NSObject, NSApplicationDelegate {
    let model = ShotModel()
    let vm = PanelViewModel()
    var store: HistoryStore!
    var backgroundWindow: NSWindow!
    var panelWindow: NSWindow!
    var captureRect = NSRect.zero
    var outDir = ""

    func applicationDidFinishLaunching(_ note: Notification) {
        guard let screen = NSScreen.main else { fatalError("no screen") }
        let scale = screen.backingScaleFactor

        // Largest 16:10 region centered in the visible area (below menu bar, above dock).
        let vf = screen.visibleFrame
        let aspect = 16.0 / 10.0
        var w = vf.width
        var h = w / aspect
        if h > vf.height { h = vf.height; w = h * aspect }
        let rx = vf.minX + (vf.width - w) / 2
        let ry = vf.minY + (vf.height - h) / 2
        captureRect = NSRect(x: rx, y: ry, width: w, height: h)

        outDir = FileManager.default.currentDirectoryPath + "/build/appstore/screenshots"
        try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

        store = HistoryStore()
        vm.selection = 0

        // Background window == the capture region, so headline layout is exact.
        backgroundWindow = NSWindow(contentRect: captureRect, styleMask: .borderless,
                                    backing: .buffered, defer: false)
        backgroundWindow.isOpaque = true
        backgroundWindow.level = .normal
        backgroundWindow.contentView = NSHostingView(
            rootView: ShotBackground(model: model, height: h))
        backgroundWindow.setFrame(captureRect, display: true)
        backgroundWindow.orderFrontRegardless()

        // The real frosted-glass panel, centered horizontally, in the lower-middle.
        let pw = PanelController.panelSize.width
        let ph = PanelController.panelSize.height
        let px = captureRect.midX - pw / 2
        let py = captureRect.minY + h * (1 - 0.58) - ph / 2
        panelWindow = NSWindow(contentRect: NSRect(x: px, y: py, width: pw, height: ph),
                               styleMask: .borderless, backing: .buffered, defer: false)
        panelWindow.isOpaque = false
        panelWindow.backgroundColor = .clear
        panelWindow.hasShadow = true
        panelWindow.level = .floating
        let view = HistoryView(
            store: store, vm: vm,
            onPaste: { _ in }, onTogglePin: { _ in }, onDelete: { _ in }, onClearAll: {})
        panelWindow.contentView = NSHostingView(rootView: view)
        panelWindow.orderFrontRegardless()

        // CGImage-pixel rect for cropping a full-display capture (top-left origin).
        let primaryH = NSScreen.screens.first!.frame.height
        let cropX = Int(captureRect.minX * scale)
        let cropY = Int((primaryH - captureRect.maxY) * scale)
        let cropW = Int(captureRect.width * scale)
        let cropH = Int(captureRect.height * scale)

        // Park the cursor in the center so an auto-hide Dock never reveals into a shot.
        CGWarpMouseCursorPosition(CGPoint(x: captureRect.midX,
                                          y: primaryH - captureRect.midY))
        NSApp.activate(ignoringOtherApps: true)
        spin(0.5) // let the windows composite on top before the first capture

        for shot in shots {
            ThemeStore.shared.current = shot.theme
            model.theme = shot.theme
            model.headline = shot.headline
            model.subhead = shot.subhead
            // Keep our windows frontmost every iteration so a capture never races.
            backgroundWindow.orderFrontRegardless()
            panelWindow.orderFrontRegardless()
            spin(0.8) // let SwiftUI render + the behind-window blur settle

            let path = "\(outDir)/\(shot.file)"
            // Capture the whole display, then crop precisely — region capture's
            // -R rounding can clip the panel shadow; cropping is exact.
            let full = "\(outDir).full.png"
            run("/usr/sbin/screencapture", ["-x", "-t", "png", "-D", "1", full])
            run("/usr/bin/sips", ["-c", "\(cropH)", "\(cropW)",
                                  "--cropOffset", "\(cropY)", "\(cropX)",
                                  full, "--out", path])
            // Normalize to App Store's 2880x1800.
            run("/usr/bin/sips", ["-z", "1800", "2880", path])
            FileManager.default.fileExists(atPath: path)
                ? print("✓ \(shot.file)") : print("✗ \(shot.file)")
            try? FileManager.default.removeItem(atPath: full)
        }

        print("Screenshots written to \(outDir)")
        NSApp.terminate(nil)
    }
}

// MARK: - Entry

let backup = seedHistory()
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let runner = Runner()
app.delegate = runner
// Restore the user's real clipboard history no matter how we exit.
let restore = { restoreHistory(backup) }
atexit_b { restore() }
app.run()
