// Draws zidev's app icon (1024 px): a dark window, a sidebar of sessions with their status dots,
// the selected one on a gray bar, and Claude's prompt on the right.  swift icon.swift out.png
import AppKit

let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!  // 1024 pixels, whatever the screen's scale
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let g = NSGraphicsContext.current!.cgContext

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

func rounded(_ r: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

// the macOS icon grid: an 824 px body, 100 px margin, a soft shadow below
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
g.saveGState()
g.setShadow(offset: CGSize(width: 0, height: -14), blur: 36, color: rgb(0x000000, 0.35))
g.addPath(rounded(body, 186))
g.setFillColor(rgb(0x111318))
g.fillPath()
g.restoreGState()

g.saveGState()
g.addPath(rounded(body, 186))
g.clip()
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let shade = CGGradient(colorsSpace: space, colors: [rgb(0x262a33), rgb(0x0f1115)] as CFArray, locations: [0, 1])!
g.drawLinearGradient(shade, start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 100), options: [])

// the sidebar
let side = CGRect(x: 100, y: 100, width: 330, height: 824)
g.setFillColor(rgb(0x1a1d24))
g.fill(side)
g.setFillColor(rgb(0x30343d))
g.fill(CGRect(x: 430, y: 100, width: 4, height: 824))

// rows: status dot + title bar; the second is selected
let rows: [(dot: UInt32, width: CGFloat)] = [(0x5fc96f, 170), (0xe5c453, 160), (0x6b7079, 140), (0x6b7079, 180)]
for (i, row) in rows.enumerated() {
    let y = 760 - CGFloat(i) * 118
    if i == 1 {
        g.setFillColor(rgb(0x3a3e47))
        g.addPath(rounded(CGRect(x: 124, y: y - 34, width: 282, height: 88), 22))
        g.fillPath()
    }
    g.setFillColor(rgb(row.dot))
    g.fillEllipse(in: CGRect(x: 152, y: y - 8, width: 36, height: 36))
    g.setFillColor(rgb(0xd4d7dd, i == 1 ? 0.95 : 0.55))
    g.addPath(rounded(CGRect(x: 212, y: y - 2, width: row.width, height: 24), 12))
    g.fillPath()
}

// the right side: Claude's answer lines and a prompt
for (i, w) in [CGFloat(330), 270, 300, 190].enumerated() {
    g.setFillColor(rgb(0xd4d7dd, 0.35))
    g.addPath(rounded(CGRect(x: 494, y: 770 - CGFloat(i) * 62, width: w, height: 22), 11))
    g.fillPath()
}
g.setStrokeColor(rgb(0xe8875f))
g.setLineWidth(30)
g.setLineCap(.round)
g.setLineJoin(.round)
g.move(to: CGPoint(x: 510, y: 360))
g.addLine(to: CGPoint(x: 580, y: 300))
g.addLine(to: CGPoint(x: 510, y: 240))
g.strokePath()
g.setFillColor(rgb(0xd4d7dd, 0.9))
g.addPath(rounded(CGRect(x: 622, y: 278, width: 60, height: 44), 8))
g.fillPath()
g.restoreGState()

// a fine light edge
g.addPath(rounded(body.insetBy(dx: 1.5, dy: 1.5), 185))
g.setStrokeColor(rgb(0xffffff, 0.08))
g.setLineWidth(3)
g.strokePath()

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
