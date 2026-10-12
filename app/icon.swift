// Draws zidev's app icon (1024 px): the prompt `> zi`, mint and white on deep night blue.  swift icon.swift out.png
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
// deep night blue, a little lighter at the top
g.drawLinearGradient(gradient([rgb(0x13294a), rgb(0x020d1a)], [0, 1]),
                     start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 100), options: [])

// the prompt `> zi`, centered as one: a mint chevron, then "zi" in white
let font = NSFont(name: "SFMono-Heavy", size: 250) ?? NSFont.monospacedSystemFont(ofSize: 250, weight: .heavy)
let text = NSAttributedString(string: "zi", attributes: [.font: font, .foregroundColor: NSColor.white])
let line = CTLineCreateWithAttributedString(text)
let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
let chevron: CGFloat = 70, gap: CGFloat = 56
let left = 512 - (chevron + gap + width) / 2
let mid: CGFloat = 500
g.setStrokeColor(rgb(0x38ff9d))
g.setLineWidth(48)
g.setLineCap(.round)
g.setLineJoin(.round)
g.move(to: CGPoint(x: left, y: mid + chevron))
g.addLine(to: CGPoint(x: left + chevron, y: mid))
g.addLine(to: CGPoint(x: left, y: mid - chevron))
g.strokePath()
g.textPosition = CGPoint(x: left + chevron + gap, y: mid - font.xHeight / 2)
CTLineDraw(line, g)
g.restoreGState()

// a fine light edge
g.addPath(CGPath(roundedRect: body.insetBy(dx: 1.5, dy: 1.5), cornerWidth: 185, cornerHeight: 185, transform: nil))
g.setStrokeColor(rgb(0xffffff, 0.10))
g.setLineWidth(3)
g.strokePath()

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
