// Draws zidev's app icon (1024 px): a prompt `> zi` glowing on deep night blue, the colors of zidev's
// iTerm profile.  swift icon.swift out.png
import AppKit

let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!  // 1024 pixels, whatever the screen's scale
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let g = NSGraphicsContext.current!.cgContext
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

func gradient(_ colors: [CGColor], _ locations: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: space, colors: colors as CFArray, locations: locations)!
}

// the macOS icon grid: an 824 px body, 100 px margin, a soft shadow below
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let shape = CGPath(roundedRect: body, cornerWidth: 186, cornerHeight: 186, transform: nil)
g.saveGState()
g.setShadow(offset: CGSize(width: 0, height: -16), blur: 40, color: rgb(0x000000, 0.45))
g.addPath(shape)
g.setFillColor(rgb(0x010c18))
g.fillPath()
g.restoreGState()

g.saveGState()
g.addPath(shape)
g.clip()
// night blue, lighter at the top
g.drawLinearGradient(gradient([rgb(0x0e3355), rgb(0x061a30), rgb(0x010811)], [0, 0.5, 1]),
                     start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 100), options: [])
// a mint glow behind the prompt
g.drawRadialGradient(gradient([rgb(0x38ff9d, 0.22), rgb(0x38ff9d, 0)], [0, 1]),
                     startCenter: CGPoint(x: 512, y: 512), startRadius: 0,
                     endCenter: CGPoint(x: 512, y: 512), endRadius: 430, options: [])
// faint scan lines, like a screen
for y in stride(from: CGFloat(100), to: 924, by: 12) {
    g.setFillColor(rgb(0xffffff, 0.018))
    g.fill(CGRect(x: 100, y: y, width: 824, height: 5))
}

// the prompt: a chevron, then "zi" and a cursor, with a glow
func glowing(_ color: UInt32, _ draw: () -> Void) {
    g.saveGState()
    g.setShadow(offset: .zero, blur: 46, color: rgb(color, 0.85))
    draw()
    g.restoreGState()
    draw()
}

let font = NSFont(name: "MesloLGS-NF-Bold", size: 300) ?? NSFont.monospacedSystemFont(ofSize: 300, weight: .heavy)
let text = NSAttributedString(string: "zi", attributes: [.font: font, .foregroundColor: NSColor(cgColor: rgb(0xecdef4))!])
let line = CTLineCreateWithAttributedString(text)
let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
// chevron, gap, "zi", gap, cursor: centered as one, on the middle of the x-height
let chevron: CGFloat = 116, cursor: CGFloat = 40
let left = 512 - (chevron + 64 + width + 16 + cursor) / 2
let baseline = 512 - font.xHeight / 2

glowing(0x38ff9d) {
    g.setStrokeColor(rgb(0x52ffd0))
    g.setLineWidth(56)
    g.setLineCap(.round)
    g.setLineJoin(.round)
    g.move(to: CGPoint(x: left, y: 512 + chevron))
    g.addLine(to: CGPoint(x: left + chevron, y: 512))
    g.addLine(to: CGPoint(x: left, y: 512 - chevron))
    g.strokePath()
}
glowing(0xc792ea) {
    g.textPosition = CGPoint(x: left + chevron + 64, y: baseline)
    CTLineDraw(line, g)
}
glowing(0x38ff9d) {
    g.setFillColor(rgb(0x38ff9d))
    g.fill(CGRect(x: left + chevron + 64 + width + 16, y: baseline - 6, width: cursor, height: font.xHeight + 12))
}

// a gloss on the upper half
g.drawLinearGradient(gradient([rgb(0xffffff, 0.10), rgb(0xffffff, 0)], [0, 1]),
                     start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 560), options: [])
g.restoreGState()

// a fine light edge
g.addPath(CGPath(roundedRect: body.insetBy(dx: 1.5, dy: 1.5), cornerWidth: 185, cornerHeight: 185, transform: nil))
g.setStrokeColor(rgb(0xffffff, 0.12))
g.setLineWidth(3)
g.strokePath()

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
