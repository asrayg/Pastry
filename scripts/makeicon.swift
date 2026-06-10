// Renders the Pastry app icon at all .iconset sizes.
// Usage: swift scripts/makeicon.swift <output-iconset-dir>
import AppKit

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func render(pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    let f = CGFloat(pixels)
    // Apple's icon grid: artwork is inset from the canvas edges.
    let inset = f * 0.09
    let rect = NSRect(x: inset, y: inset, width: f - 2 * inset, height: f - 2 * inset)
    let radius = rect.width * 0.225
    let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 1.00, green: 0.64, blue: 0.42, alpha: 1),
        NSColor(calibratedRed: 0.93, green: 0.33, blue: 0.55, alpha: 1),
    ])!
    gradient.draw(in: squircle, angle: -70)

    if let symbol = NSImage(systemSymbolName: "doc.on.clipboard.fill", accessibilityDescription: nil),
       let configured = symbol.withSymbolConfiguration(.init(pointSize: f * 0.40, weight: .medium)) {
        let tinted = NSImage(size: configured.size)
        tinted.lockFocus()
        configured.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1)
        NSColor.white.set()
        NSRect(origin: .zero, size: configured.size).fill(using: .sourceAtop)
        tinted.unlockFocus()

        let origin = NSPoint(
            x: (f - tinted.size.width) / 2,
            y: (f - tinted.size.height) / 2
        )
        tinted.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1)
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let entries: [(Int, String)] = [
    (16, "icon_16x16"), (32, "icon_16x16@2x"),
    (32, "icon_32x32"), (64, "icon_32x32@2x"),
    (128, "icon_128x128"), (256, "icon_128x128@2x"),
    (256, "icon_256x256"), (512, "icon_256x256@2x"),
    (512, "icon_512x512"), (1024, "icon_512x512@2x"),
]

for (pixels, name) in entries {
    let rep = render(pixels: pixels)
    let png = rep.representation(using: .png, properties: [:])!
    let url = URL(fileURLWithPath: outDir).appendingPathComponent("\(name).png")
    try! png.write(to: url)
}
print("Rendered \(entries.count) icons into \(outDir)")
