// Draws the disk image window's background: the app under a street lamp, an arrow to Applications,
// and a drift of snow for the icon labels to sit on, mid-toned so Finder's black or white labels both read.
// Usage: swift scripts/make-dmg-background.swift <output.png> <scale>
import AppKit

let output = CommandLine.arguments[1]
let scale = CGFloat(Double(CommandLine.arguments[2]) ?? 1)
let size = CGSize(width: 640, height: 400)
// Finder centres each icon on these points, measured from the window's top left.
let appCenter = CGPoint(x: 170, y: 200)
let applicationsCenter = CGPoint(x: 470, y: 200)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(size.width * scale), height: Int(size.height * scale), bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.scaleBy(x: scale, y: scale)
// Drawn top-down like Finder lays the window out.
ctx.translateBy(x: 0, y: size.height)
ctx.scaleBy(x: 1, y: -1)

let night = CGGradient(colorsSpace: space, colors: [color(0x1e0e26), color(0x0d0612)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(night, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])

let lamp = CGPoint(x: appCenter.x, y: 34)
let halo = CGGradient(colorsSpace: space, colors: [color(0xff9d36, 0.38), color(0xff6b1a, 0.12), color(0xff6b1a, 0)] as CFArray,
                      locations: [0, 0.4, 1])!
ctx.drawRadialGradient(halo, startCenter: lamp, startRadius: 0, endCenter: lamp, endRadius: 230, options: [])
for layer in 0..<30 {
    let spread = 70 + CGFloat(layer) * 3.2
    let beam = CGMutablePath()
    beam.move(to: CGPoint(x: lamp.x - 7, y: lamp.y))
    beam.addLine(to: CGPoint(x: lamp.x + 7, y: lamp.y))
    beam.addLine(to: CGPoint(x: lamp.x + spread, y: size.height))
    beam.addLine(to: CGPoint(x: lamp.x - spread, y: size.height))
    beam.closeSubpath()
    ctx.saveGState()
    ctx.addPath(beam)
    ctx.clip()
    let light = CGGradient(colorsSpace: space, colors: [color(0xffaa42, 0.024), color(0xff7718, 0.002)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(light, start: CGPoint(x: 0, y: lamp.y), end: CGPoint(x: 0, y: size.height), options: [])
    ctx.restoreGState()
}
ctx.setFillColor(color(0x281a24))
ctx.fill(CGRect(x: 0, y: lamp.y - 15, width: lamp.x, height: 2))
let head = CGMutablePath()
head.move(to: CGPoint(x: lamp.x - 15, y: lamp.y))
head.addLine(to: CGPoint(x: lamp.x + 15, y: lamp.y))
head.addLine(to: CGPoint(x: lamp.x + 7, y: lamp.y - 12))
head.addLine(to: CGPoint(x: lamp.x - 7, y: lamp.y - 12))
head.closeSubpath()
ctx.setFillColor(color(0x281a24))
ctx.addPath(head)
ctx.fillPath()
ctx.setFillColor(color(0xffb84d))
ctx.fillEllipse(in: CGRect(x: lamp.x - 9, y: lamp.y - 1.5, width: 18, height: 4))

let flakes: [(CGFloat, CGFloat, CGFloat)] = [
    (120, 80, 2.8), (205, 104, 2.2), (148, 132, 3.2), (232, 150, 2.0), (96, 160, 2.1), (190, 62, 1.9),
    (318, 70, 1.7), (402, 118, 2.0), (560, 84, 1.8), (604, 150, 2.2), (512, 180, 1.6), (352, 160, 1.8),
    (44, 108, 1.8), (276, 116, 1.6), (448, 56, 1.7),
]
for (x, y, r) in flakes {
    let lit = abs(x - lamp.x) < 20 + (y - lamp.y) * 0.45
    let center = CGPoint(x: x, y: y)
    let glow = CGGradient(colorsSpace: space,
                          colors: [color(lit ? 0xffb347 : 0xc84b1e, lit ? 0.95 : 0.65), color(lit ? 0xff6e1a : 0x8a2814, 0)] as CFArray,
                          locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: center, startRadius: 0, endCenter: center, endRadius: r * (lit ? 2.6 : 1.8), options: [])
}

let drift = CGMutablePath()
drift.move(to: CGPoint(x: -5, y: size.height + 5))
drift.addLine(to: CGPoint(x: -5, y: 262))
drift.addCurve(to: CGPoint(x: 230, y: 266), control1: CGPoint(x: 70, y: 250), control2: CGPoint(x: 150, y: 274))
drift.addCurve(to: CGPoint(x: 430, y: 258), control1: CGPoint(x: 300, y: 258), control2: CGPoint(x: 360, y: 250))
drift.addCurve(to: CGPoint(x: size.width + 5, y: 264), control1: CGPoint(x: 520, y: 268), control2: CGPoint(x: 590, y: 252))
drift.addLine(to: CGPoint(x: size.width + 5, y: size.height + 5))
drift.closeSubpath()
ctx.saveGState()
ctx.addPath(drift)
ctx.clip()
let snow = CGGradient(colorsSpace: space, colors: [color(0x9c461c), color(0x632814), color(0x2e1312)] as CFArray, locations: [0, 0.45, 1])!
ctx.drawLinearGradient(snow, start: CGPoint(x: 0, y: 250), end: CGPoint(x: 0, y: size.height), options: [])
let pool = CGPoint(x: lamp.x, y: 262)
let lit = CGGradient(colorsSpace: space, colors: [color(0xff9c38, 0.55), color(0xff6b1a, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(lit, startCenter: pool, startRadius: 0, endCenter: pool, endRadius: 150, options: [])
let crust = CGGradient(colorsSpace: space, colors: [color(0xffb84d, 0.30), color(0xffb84d, 0)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(crust, start: CGPoint(x: 0, y: 252), end: CGPoint(x: 0, y: 268), options: [])
ctx.restoreGState()

let arrowY = appCenter.y
let arrow = CGMutablePath()
arrow.move(to: CGPoint(x: 262, y: arrowY))
arrow.addLine(to: CGPoint(x: 376, y: arrowY))
arrow.move(to: CGPoint(x: 366, y: arrowY - 7))
arrow.addLine(to: CGPoint(x: 377, y: arrowY))
arrow.addLine(to: CGPoint(x: 366, y: arrowY + 7))
ctx.setStrokeColor(color(0xede6da, 0.75))
ctx.setLineWidth(1.5)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.addPath(arrow)
ctx.strokePath()

NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
let caption = NSAttributedString(string: "DRAG TO APPLICATIONS", attributes: [
    .font: NSFont.systemFont(ofSize: 11, weight: .medium, width: .condensed),
    .foregroundColor: NSColor(srgbRed: 0.93, green: 0.9, blue: 0.85, alpha: 0.7),
    .kern: 2.2,
])
let captionSize = caption.size()
caption.draw(at: CGPoint(x: (appCenter.x + applicationsCenter.x) / 2 - captionSize.width / 2, y: arrowY - 26))
NSGraphicsContext.current = nil

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
rep.size = size
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
