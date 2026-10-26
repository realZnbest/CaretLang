// Renders Resources/AppIcon.icns — run: swift tools/make-icon.swift
import Cocoa

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255, alpha: a)
}

func drawIcon(_ size: CGFloat) -> NSBitmapImageRep {
    let px = Int(size)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = size / 1024

    // พื้นหลังทรง squircle ตามขนาดไอคอน macOS (824 บน canvas 1024)
    let body = NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let bg = NSBezierPath(roundedRect: body, xRadius: 185 * s, yRadius: 185 * s)
    NSGradient(starting: hex(0x2E3A59), ending: hex(0x141826))!.draw(in: bg, angle: -90)

    // เคอร์เซอร์ตัว I
    hex(0xFFFFFF).setFill()
    let cx = 400 * s
    NSBezierPath(roundedRect: NSRect(x: cx - 14 * s, y: 330 * s, width: 28 * s, height: 400 * s), xRadius: 14 * s, yRadius: 14 * s).fill()
    NSBezierPath(roundedRect: NSRect(x: cx - 80 * s, y: 706 * s, width: 160 * s, height: 28 * s), xRadius: 14 * s, yRadius: 14 * s).fill()
    NSBezierPath(roundedRect: NSRect(x: cx - 80 * s, y: 326 * s, width: 160 * s, height: 28 * s), xRadius: 14 * s, yRadius: 14 * s).fill()

    // ป้ายธงไทยใต้เคอร์เซอร์ เยื้องขวา
    let pill = NSRect(x: 430 * s, y: 190 * s, width: 400 * s, height: 170 * s)
    hex(0x000000, 0.85).setFill()
    NSBezierPath(roundedRect: pill, xRadius: 40 * s, yRadius: 40 * s).fill()

    let flag = NSRect(x: pill.minX + 36 * s, y: pill.midY - 54 * s, width: 144 * s, height: 108 * s)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: flag, xRadius: 16 * s, yRadius: 16 * s).addClip()
    let u = flag.height / 6
    var y = flag.maxY
    for (c, n) in [(hex(0xA51931), 1.0), (hex(0xF4F5F8), 1.0), (hex(0x2D2A4A), 2.0), (hex(0xF4F5F8), 1.0), (hex(0xA51931), 1.0)] {
        c.setFill()
        NSRect(x: flag.minX, y: y - u * n, width: flag.width, height: u * n).fill()
        y -= u * n
    }
    NSGraphicsContext.restoreGraphicsState()

    let text = NSAttributedString(string: "ก", attributes: [
        .font: NSFont.systemFont(ofSize: 120 * s, weight: .bold), .foregroundColor: NSColor.white])
    let ts = text.size()
    text.draw(at: NSPoint(x: flag.maxX + (pill.maxX - flag.maxX - ts.width) / 2, y: pill.midY - ts.height / 2))

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let set = root.appendingPathComponent("build/AppIcon.iconset")
try? FileManager.default.removeItem(at: set)
try! FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        let png = drawIcon(CGFloat(base * scale)).representation(using: .png, properties: [:])!
        try! png.write(to: set.appendingPathComponent(name))
    }
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", set.path, "-o", root.appendingPathComponent("Resources/AppIcon.icns").path]
try! p.run()
p.waitUntilExit()
print("Wrote Resources/AppIcon.icns")
